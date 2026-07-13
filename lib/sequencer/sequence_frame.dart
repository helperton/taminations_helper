/*

  Taminations Square Dance Animations
  Copyright (C) 2026 Brad Christie

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/


import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart' as fm;
import 'package:flutter/services.dart' as fs;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as pp;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';

import '../common_flutter.dart';
import '../dance_painter.dart';
import '../pages/calls_page.dart';
import '../pages/page.dart';
import '../resolve_client.dart';
import 'abbreviations_model.dart';
import 'resolver_panel_controller.dart';
import 'sequencer_model.dart';
import 'words.dart';

class SequenceFrame extends fm.StatefulWidget {
  @override
  _SequenceFrameState createState() => _SequenceFrameState();
}

class _SequenceFrameState extends fm.State<SequenceFrame> {

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  @override
  fm.Widget build(fm.BuildContext context) {
    return pp.Consumer2<SequencerModel, DanceThemeTuning>(
         builder: (context, model, tuning, child) {
           final isDark = fm.Theme.of(context).brightness == fm.Brightness.dark;
           final backgroundColor = isDark ? tuning.darkFloorColor : null;
           return fm.LayoutBuilder(
             builder: (context,constraints) => fm.Column(
               children: [
                 SequencerEditLine(),
                 if (!isSmallAndCompact(context))
                   fm.Expanded(
                       child: fm.Container(
                         color: backgroundColor,
                       child: ScrollablePositionedList.builder(
                         itemScrollController: itemScrollController,
                         itemPositionsListener: itemPositionsListener,
                         itemCount: model.calls.length,
                         itemBuilder: itemBuilder,
                       ))
                   ),
                 fm.Container(
                   constraints: const fm.BoxConstraints.expand(height: 1),
                     child: fm.Text(model.errorString,key: fm.Key('Error text'),style: fm.TextStyle(fontSize: 0.01)))
               ],
             ),
           );
         },
    );
  }

  //  Builder for one item of the list
  fm.Widget itemBuilder(fm.BuildContext context, int index) {
    return pp.Consumer<SequencerModel>(
        builder: (context, model, child) {
          final currentCall = model.currentCall;
          SequencerCall? call;
          try {
            call = model.calls[index];
          } on Error { call = null; };
          if (currentCall == index) {
            later(() {
              itemScrollController.scrollTo(
                  index: max(index-5, 0),
                  duration: Duration(seconds: 1),
                  curve: fm.Curves.easeInOutCubic);
            });
          }
          final isDark = fm.Theme.of(context).brightness == fm.Brightness.dark;
          final levelColor = call?.level?.color;
          final itemColor = (index == currentCall)
              ? (isDark ? const Color(0xFFE6A800) : Color.YELLOW)
              : isDark
                  ? (levelColor?.darker(0.45) ?? const Color(0xFF2A2A2A))
                  : (levelColor ?? Color.WHITE);
          final borderColor = isDark ? const Color(0xFF444444) : Color.BLACK;
          return fm.Container(
            decoration: fm.BoxDecoration(
                border: fm.Border(top: fm.BorderSide(width: 1, color: borderColor))),
            child: fm.Material(
              color: itemColor,
              //  Right-click (or long-press, for touch) any call to insert around it or delete it.
              child: fm.GestureDetector(
                onSecondaryTapDown: (details) =>
                    _showCallMenu(context, model, index, details.globalPosition),
                onLongPressStart: (details) =>
                    _showCallMenu(context, model, index, details.globalPosition),
                child: model.isComment(call?.name ?? '#')
                    ? _OneLine(call?.name ?? '','', isDark)
                    : fm.InkWell(
                        highlightColor: levelColor?.darker() ?? Color.WHITE,
                        onTap: () {
                          model.animateAtCall(index);
                        },
                        child: _OneLine(call?.name ?? '',call?.level?.name ?? '', isDark)),
              )
            )
          );
        });
  }

  Future<void> _showCallMenu(fm.BuildContext context, SequencerModel model,
      int index, fm.Offset position) async {
    final overlay =
        fm.Overlay.of(context).context.findRenderObject() as fm.RenderBox;
    final choice = await fm.showMenu<String>(
      context: context,
      position: fm.RelativeRect.fromRect(
          position & const fm.Size(1, 1), fm.Offset.zero & overlay.size),
      items: const [
        fm.PopupMenuItem(value: 'above', child: fm.Text('Insert Call Above…')),
        fm.PopupMenuItem(value: 'below', child: fm.Text('Insert Call Below…')),
        fm.PopupMenuDivider(),
        fm.PopupMenuItem(value: 'delete', child: fm.Text('Delete Call')),
      ],
    );
    if (choice == null || !context.mounted) {
      return;
    }
    switch (choice) {
      case 'above':
        await _insertCall(context, model, index);
      case 'below':
        await _insertCall(context, model, index + 1);
      case 'delete':
        _deleteCall(context, model, index);
    }
  }

  Future<void> _insertCall(
      fm.BuildContext context, SequencerModel model, int at) async {
    final controller = fm.TextEditingController();
    final entered = await fm.showDialog<String>(
        context: context,
        builder: (ctx) => fm.AlertDialog(
              title: fm.Text(at == 0 ? 'Insert Call at the Top' : 'Insert Call'),
              content: fm.TextField(
                controller: controller,
                autofocus: true,
                style: fm.TextStyle(fontSize: 24),
                decoration: fm.InputDecoration(hintText: 'Enter a call'),
                onSubmitted: (value) => fm.Navigator.of(ctx).pop(value),
              ),
              actions: [
                fm.TextButton(
                    onPressed: () => fm.Navigator.of(ctx).pop(),
                    child: fm.Text('Cancel')),
                fm.TextButton(
                    onPressed: () => fm.Navigator.of(ctx).pop(controller.text),
                    child: fm.Text('Insert')),
              ],
            ));
    if (entered == null || entered.isBlank || !context.mounted) {
      return;
    }

    final previous = model.callNames;
    final failed = model.insertCallAt(at, entered);
    if (!context.mounted) {
      return;
    }
    if (failed != null) {
      //  Either the new call doesn't work here, or it works but breaks a later one.
      _snack(
          context,
          failed.trim().toLowerCase() == entered.trim().toLowerCase()
              ? 'Cannot insert "${entered.trim()}" there. Sequence unchanged.'
              : 'Inserting "${entered.trim()}" there breaks "$failed". Sequence unchanged.',
          Color.RED);
      return;
    }
    _snack(context, 'Inserted "${entered.trim()}".', Color.BLUE,
        undo: () => model.rebuildSequence(previous));
  }

  void _deleteCall(fm.BuildContext context, SequencerModel model, int index) {
    if (index < 0 || index >= model.calls.length) {
      return;
    }
    final removed = model.calls[index].name;
    final previous = model.callNames;
    final failed = model.deleteCallAt(index);
    if (failed != null) {
      _snack(
          context,
          'Cannot delete "$removed" — "$failed" no longer works without it. '
              'Sequence unchanged.',
          Color.RED);
      return;
    }
    _snack(context, 'Deleted "$removed".', Color.BLUE,
        undo: () => model.rebuildSequence(previous));
  }

  void _snack(fm.BuildContext context, String message, Color background,
      {void Function()? undo}) {
    fm.ScaffoldMessenger.of(context).showSnackBar(fm.SnackBar(
      backgroundColor: background,
      duration: Duration(seconds: undo == null ? 4 : 6),
      content: fm.Text(message, style: GoogleFonts.roboto(fontSize: 20)),
      action: undo == null
          ? null
          : fm.SnackBarAction(
              label: 'Undo', textColor: Color.WHITE, onPressed: undo),
    ));
  }

}

class SequenceEditButtons extends fm.StatelessWidget {
  @override
  fm.Widget build(fm.BuildContext context) {
    final isDark = fm.Theme.of(context).brightness == fm.Brightness.dark;
    return pp.Consumer<DanceThemeTuning>(
      builder: (context, tuning, _) => fm.Container(
        color: isDark ? tuning.darkFloorColor : Color.FLOOR,
        child: fm.Row(
          children: [
            SequencerUndoButton(),
            SequencerResolveButton(),
            SequencerResetButton(),
            SequencerCopyButton(),
            SequencerPasteButton(),
          ]
        ),
      ),
    );
  }
}


class SequencerEditLine extends fm.StatefulWidget {
  @override
  _SequencerEditLineState createState() => _SequencerEditLineState();
}

class _SequencerEditLineState extends fm.State<SequencerEditLine> {

  fm.TextEditingController textFieldController = fm.TextEditingController();
  final focusNode = fm.FocusNode();
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  late SpeechToTextProvider speechProvider;
  var _lastError = '';
  var _isVoiceCall = false;

  @override
  void initState() {
    super.initState();
    if (!TamUtils.isTouchDevice)
      later(() {
        focusNode.requestFocus();
      });
    speechProvider = SpeechToTextProvider(SpeechToText());
  }

  @override
  void dispose() {
    textFieldController.dispose();
    fs.SystemChannels.textInput.invokeMethod('TextInput.hide');
    focusNode.dispose();
    super.dispose();
  }

  @override
  fm.Widget build(fm.BuildContext context) {
    return  pp.ChangeNotifierProvider.value(
        value: speechProvider,
        child: pp.Consumer4<SequencerModel,
            AbbreviationsModel,
            SpeechToTextProvider,
            VirtualKeyboardVisible>(
    builder: (context, model, abbreviations, speech, virtualKeyboard, child) {

      //  If doing voice input, show errors in the snack bar
      //  because the error text of the EditText is not visible
      if (_isVoiceCall && model.errorString.isNotBlank && model.errorString != _lastError) {
        _lastError = model.errorString;
        model.errorString = '';
        later(() {
          fm.ScaffoldMessenger.of(context).showSnackBar(fm.SnackBar(
              backgroundColor: Color.RED,
              duration: Duration(seconds: 2),
              content: fm.Text(_lastError,
                  style: GoogleFonts.roboto(fontSize: 20))
          ));
        });
        //  After the same duration as the SnackBar reset the last error
        //  so the user will see another messoage on repeating the same error
        afterDelay(() { _lastError = ''; },Duration(seconds:2));
      }
      //  Process any results from the speech recognizer
      if (speech.hasResults) {
        //print('Looking for ${speech.lastResult.recognizedWords}');
        var found = false;
        for (var i=0; i<speech.lastResult!.alternates.length; i++) {
          //  Look through all the alternatives for one that has
          //  all square dance words
          var call = speech.lastResult!.alternates[i].recognizedWords.replaceAll('\\W'.r, ' ');
          var words = call.split('\\s+'.r)
              .map((w) => normalizeCall(w).toLowerCase());
          if (words.every((word) => Words.words.contains(word))) {
            //print('Found call in alternative $i: $call');
            later( () {
              _isVoiceCall = true;
              _sendOneLine(model, call);
            });
            found = true;
            break;
          }
        }
        if (!found) {
          final message = speech.lastResult!.alternates.isNotEmpty
              ? 'Unable to parse, best guess is ${speech.lastResult!.alternates.first.recognizedWords}.'
              : 'Sorry, not able to recognize that.';
          later(() {
            fm.ScaffoldMessenger.of(context).showSnackBar(fm.SnackBar(
                backgroundColor: Color.RED,
                duration: Duration(seconds: 2),
                content: fm.Text(message,
                    style: GoogleFonts.roboto(fontSize: 20))
            ));
          });
        }
        later((){
          speech.stop();
          speech.listen(
              localeId: 'en_US',
              partialResults: false,
              soundLevel: true,
              listenFor: Duration(seconds: 10),
              pauseFor: Duration(seconds: 5)
          );
        });
      }

      final isDark = fm.Theme.of(context).brightness == fm.Brightness.dark;
      final themeTuning = pp.Provider.of<DanceThemeTuning>(context);
      final logBackgroundColor = isDark ? themeTuning.darkFloorColor : Color.FLOOR;
      return fm.Container(
        color: logBackgroundColor,
        padding: fm.EdgeInsets.only(left: 10),
        child: fm.Row(
          children: [

            //   Accept keyboard input if web site
            //  or if user has tapped box on a device
            if (virtualKeyboard.isVisible || !TamUtils.isTouchDevice)
              fm.Expanded(
                child: fm.TextField(
                  key: fm.Key('Sequencer Input'),
                  focusNode: focusNode,
                  controller: textFieldController,
                  onTapOutside: (event) {
                    fm.FocusManager.instance.primaryFocus?.unfocus();
                  },
                  decoration: fm.InputDecoration(
                      hintText: 'Enter calls',
                      suffixIcon: fm.IconButton(
                          icon:fm.Icon(fm.Icons.clear),
                        onPressed: () => { textFieldController.clear() },
                      ),
                      errorStyle: fm.TextStyle(fontSize: 20,
                          color: model.errorString.contains('Note') ? fm.Colors.blue : fm.Colors.red),
                      errorMaxLines: 20,
                      errorText: model.errorString.isEmpty ? null : model.errorString),
                  enableSuggestions: true,
                  style: fm.TextStyle(fontSize: 24),
                  //  Code to run when user presses Enter
                  onSubmitted: (value) {
                    _isVoiceCall = false;
                    _sendOneLine(model, value);
                  },
                ),
              )

            //  Touch device - don't show keyboard until user
            //  taps the input line
            else
              fm.Expanded(
                  child:fm.Material(
                    color: logBackgroundColor,
                    child: fm.InkWell(
                      key: fm.ValueKey('Tap to start Sequence'),
                      onTap: () {
                        setState(() {
                          virtualKeyboard.isVisible = true;
                          focusNode.requestFocus();
                        });
                      },
                      child: fm.Text('Tap mic or this space',
                          style: fm.TextStyle(fontSize: 20)),
                    ),
                  )
              ),

            //  Mic icon for touch devices to do voice input
            if (TamUtils.canListen)
              fm.TextButton(onPressed: () {
                    speechProvider.initialize().whenComplete(() {
                      if (speechProvider.isAvailable) {
                        setState(() {
                          speechProvider.listen(
                              localeId: 'en_US',
                              partialResults: false,
                              listenFor: Duration(seconds: 10),
                              pauseFor: Duration(seconds: 5)
                          );
                        });
                      } else {
                        fm.ScaffoldMessenger.of(context).showSnackBar(fm.SnackBar(
                            backgroundColor: Color.BLUE,
                            duration: Duration(seconds: 2),
                            content: fm.Text('Sorry, speech recognition not available on this device.',
                                style: GoogleFonts.roboto(fontSize: 20))));
                      }
                    } );
                  }, child: fm.Icon(
                  fm.Icons.mic,
                  color: speechProvider.isListening ? Color.RED : Color.BLACK,
                  size: 32
              )
              )
          ]
        )
      );
    }
        )
    );
  }

  void _sendOneLine(SequencerModel model, String value) async {
    var hasError = false;
    //  Process the call
    if (!(model.loadOneCall(value))) {
      hasError = true;
    }
    //  Animate from the previous position
    //if (model.animation.movingBeats > oldbeats) {
    //  model.animation.beater.beat = oldbeats;
    //  model.animation.doPlay();
    //}
    //  Erase it from the the text field, unless there's an error
    //  that the user might want to fix
    if (!hasError)
      textFieldController.clear();
    //  And get the focus back for the next call
    //  Android needs a double postpone
    later(() {
      later((){
        focusNode.requestFocus();
      });
    });
  }

}


class SequencerUndoButton extends fm.StatelessWidget {
  @override
  fm.Widget build(fm.BuildContext context) {
    final model = pp.Provider.of<SequencerModel>(context,listen: false);
    return fm.Expanded(
        child: Button('Undo',onPressed: () {
          model.undoLastCall();
        })
    );
  }
}


class SequencerResetButton extends fm.StatelessWidget {
  @override
  fm.Widget build(fm.BuildContext context) {
    final model = pp.Provider.of<SequencerModel>(context,listen: false);
    return fm.Expanded(
        child: Button('Reset',onPressed: () {
          model.reset();
        })
    );
  }
}

class SequencerResolveButton extends fm.StatefulWidget {
  @override
  fm.State<SequencerResolveButton> createState() => _SequencerResolveButtonState();
}

class _SequencerResolveButtonState extends fm.State<SequencerResolveButton> {
  @override
  fm.Widget build(fm.BuildContext context) {
    return fm.Expanded(
      child: Button('Resolve', onPressed: () {
        pp.Provider.of<ResolverPanelController>(context, listen: false).open();
      }),
    );
  }
}

/// Actions invoked by the resolve pushout panel's buttons. Static so the panel
/// (rendered elsewhere in the tree, in sequencer_page) can drive the resolve
/// flow against the providers.
extension SequencerResolveActions on SequencerResolveButton {
  static Future<void> go(fm.BuildContext context) async {
    final model = pp.Provider.of<SequencerModel>(context, listen: false);
    final controller =
        pp.Provider.of<ResolverPanelController>(context, listen: false);
    if (model.calls.isEmpty) {
      controller.applyResult(
          const ResolveResult(resolved: false, note: 'Nothing to resolve.'),
          baselineCount: 0);
      return;
    }
    controller.beginResolving();
    final overrides = danceabilityOverrides(
      lane: Settings.danceabilityLaneWeight,
      overlap: Settings.danceabilityOverlapWeight,
      dist: Settings.danceabilityDistWeight,
      threshold: Settings.danceabilityThreshold,
      blockWidth: Settings.danceabilityBlockWidth,
    );
    final calls = model.calls.map((c) => c.name).toList();
    // model + controller were read before the await, so no post-await context use.
    final result = await ResolveClient.resolve(calls, overrides: overrides);
    controller.applyResult(result, baselineCount: model.calls.length);
  }

  static void forward(fm.BuildContext context) {
    final model = pp.Provider.of<SequencerModel>(context, listen: false);
    final controller =
        pp.Provider.of<ResolverPanelController>(context, listen: false);
    final call = controller.nextCall();
    if (call == null) return;
    if (model.loadOneCall(call)) {
      controller.didLoadForward();
    }
  }

  static void back(fm.BuildContext context) {
    final model = pp.Provider.of<SequencerModel>(context, listen: false);
    final controller =
        pp.Provider.of<ResolverPanelController>(context, listen: false);
    if (!controller.canBack()) return;
    model.undoLastCall();
    controller.didUndoBack();
  }

  static void accept(fm.BuildContext context) {
    pp.Provider.of<ResolverPanelController>(context, listen: false).close();
  }

  static void dismiss(fm.BuildContext context) {
    final model = pp.Provider.of<SequencerModel>(context, listen: false);
    final controller =
        pp.Provider.of<ResolverPanelController>(context, listen: false);
    while (model.calls.length > controller.baseline) {
      model.undoLastCall();
    }
    controller.close();
  }

  static void cancel(fm.BuildContext context) {
    pp.Provider.of<ResolverPanelController>(context, listen: false).close();
  }
}

class SequencerCopyButton extends fm.StatelessWidget {
  @override
  fm.Widget build(fm.BuildContext context) {
    final model = pp.Provider.of<SequencerModel>(context,listen: false);
    return fm.Expanded(
        child: Button('Copy',onPressed: () {
          model.copy();
          final count = model.calls.length;
          final countText = count == 1 ? '1 call' : '$count calls';
          fm.ScaffoldMessenger.of(context).showSnackBar(fm.SnackBar(
              backgroundColor: Color.BLUE,
              duration: Duration(seconds: 2),
              content: fm.Text('$countText copied to Clipboard.',
                  style: GoogleFonts.roboto(fontSize: 20))
          ));
        })
    );
  }
}

class SequencerPasteButton extends fm.StatelessWidget {

  Future<void> pasteDialog(fm.BuildContext context, String text) async {
    final model = pp.Provider.of<SequencerModel>(context,listen: false);
    final controller = fm.TextEditingController()..text = text;
    final here = text.isBlank ? ' Here' :  '';
    await fm.showDialog(context: context, builder: (ctx) =>
        fm.AlertDialog(
          title: fm.Text('Paste Sequence$here'),
          content: fm.TextField(
            controller: controller,
            maxLines: null,
          ),
          actions: [
            fm.TextButton(onPressed: () {
              fm.Navigator.of(context).pop();
              model.paste(controller.text);
            }, child: fm.Text('OK')),
            fm.TextButton(onPressed: () {
              fm.Navigator.of(context).pop();
            }, child: fm.Text('Cancel'))
          ],
        ));
  }

  @override
  fm.Widget build(fm.BuildContext context) {
    return fm.Expanded(
        child: Button('Paste',onPressed: () {
          //  Show the calls to paste
          //  and let the user confirm and edit
          fs.Clipboard.getData('text/plain').then((value) async {
            if (value is fs.ClipboardData) {
              await pasteDialog(context, value.text ?? '');
            }
            else  //  Sometimes Firefox goes here
              await pasteDialog(context, '');
          },
              //  Firefox does not support Clipboard, so let the user paste with ^V
              onError: (Object obj) async {
                await pasteDialog(context, '');
              }
          );
        })
    );
  }
}

class _OneLine extends fm.StatelessWidget {
  final String name;
  final String level;
  final bool isDark;
  _OneLine(this.name,[this.level='', this.isDark = false]);

  @override
  fm.Widget build(fm.BuildContext context) {
    final textColor = isDark ? Color.WHITE : Color.BLACK;
    return fm.Row(
      children: [
        fm.Flexible(
          child: fm.Container(
              alignment: fm.Alignment.centerLeft,
              padding: fm.EdgeInsets.only(left: 20.0),
              child: AutoSizeText(name, style: fm.TextStyle(fontSize: 20, color: textColor))
          ),
        ),
        fm.Container(
            alignment: fm.Alignment.topRight,
            padding: fm.EdgeInsets.only(top:2,right:2),
            child: fm.Text(level, style: fm.TextStyle(color: textColor.darker()))
        )
      ],
    );
  }
}
