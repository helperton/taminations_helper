//  This table is indexed by the call name, and gives the title (what to show above the animation),
//  and the link and name to send to the Taminations program to fetch the animation
var calls = {
circleleft : { title:'Circle Left', link:'ssd/circle', animation:'CircleLeft' },
circleright : { title:'Circle Right', link:'ssd/circle', animation:'CircleRight' },
forwardandback : { title:'Forward and Back', link:'ssd/forward_and_back', animation:'ForwardandBackfromLines' },
dosado : { title:'Dosado', link:'ssd/dosado', animation:'DosadoFromFacingCouples' },
swing : { title:'Swing Your Partner', link:'ssd/swing', animation:'SwingYourPartnerfromFacingCouples' },
couplespromenade : { title:'All 4 Couples Promenade', link:'ssd/promenade', animation:'All4CouplesPromenadeFull' },
singlefilepromenade : { title:'Four Girls Promenade', link:'ssd/promenade', animation:'FourGirlsPromenade' },
wrongwaypromenade : { title:'Heads Wrong Way Promenade Half Way', link:'ssd/promenade', animation:'HeadsWrongWayPromenade12' },
starpromenade : { title:'Star Promenade', link:'ssd/promenade', animation:'StarPromenade' },
allemandeleft : { title:'Allemande Left', link:'ssd/allemande', animation:'AllemandeLeftfromStaticSquare' },
armturns : { title:'Turn Partner by the Right', link:'ssd/arm_turns', animation:'TurnPartnerbytheRight' },
rightandleftgrand : { title:'Right and Left Grand', link:'ssd/right_and_left_grand', animation:'RightandLeftGrandfromGrandCircle' },
weavethering : { title:'Weave the Ring', link:'ssd/right_and_left_grand', animation:'WeavetheRing' },
wrongwaygrand : { title:'Wrong Way Grand', link:'ssd/right_and_left_grand', animation:'WrongWayGrandfromGrandCircle' },
lefthandstar : { title:'Heads Left-Hand Star', link:'ssd/star', animation:'HeadsLeftHandStarAlltheWayAround' },
righthandstar : { title:'Heads Right-Hand Star', link:'ssd/star', animation:'HeadsRightHandStarAlltheWayAround' },
courtesyturn : { title:'Courtesy Turn', link:'ssd/courtesy_turn', animation:'CourtesyTurnfromCouplesFacingOut' },
twoladieschain : { title:'Head Ladies Chain', link:'ssd/ladies_chain', animation:'HeadLadiesChain' },
fourladieschain : { title:'Four Ladies Chain', link:'ssd/ladies_chain', animation:'FourLadiesChainfromStaticSquare' },
passthru : { title:'Pass Thru', link:'ssd/pass_thru', animation:'PassThrufromEightChainThru' },
wheelaround : { title:'Wheel Around', link:'ssd/wheel_around', animation:'WheelAroundfromCouplesFacingOut' },
reversewheelaround : { title:'Reverse Wheel Around', link:'ssd/wheel_around', animation:'ReverseWheelAroundfromCouplesFacingOut' },
starthru : { title:'Star Thru', link:'ssd/star_thru', animation:'StarThrufromFacingCouples' },
slidethru : { title:'Slide Thru', link:'ssd/slide_thru', animation:'SlideThrufromFacingCouples' },
halfsashay : { title:'Half Sashay', link:'ssd/sashay', animation:'HalfSashayfromFacingCouples' },
rollaway : { title:'Rollaway', link:'ssd/sashay', animation:'RollawayfromCircleLeft' },
ladiesinmensashay : { title:'Ladies In, Men Sashay', link:'ssd/sashay', animation:'LadiesInMenSashayfromCircleLeft' },
californiatwirl : { title:'California Twirl', link:'ssd/california_twirl', animation:'CaliforniaTwirlfromCouplesFacingOut' },
bendtheline : { title:'Bend the Line', link:'ssd/bend_the_line', animation:'BendtheLinefromLinesFacingOut' },
uturnback : { title:'U-Turn Back', link:'ssd/turn_back', animation:'UTurnBackfromCouplesFacingOut' },
backtrack : { title:'Girls Backtrack', link:'ssd/turn_back', animation:'GirlsBacktrackfromPromenade' },
divethru : { title:'Dive Thru', link:'ssd/dive_thru', animation:'DiveThru' },
squarethru : { title:'Heads Square Thru 4', link:'ssd/square_thru', animation:'HeadsSquareThru4' },
grandsquare : { title:'Sides Face, Grand Square', link:'ssd/grand_square', animation:'SidesFaceGrandSquare' },
leadright : { title:'Heads Lead Right', link:'ssd/lead_right', animation:'HeadsLeadRight' },
leadleft : { title:'Heads Lead Left', link:'ssd/lead_right', animation:'HeadsLeadLeft' },
veerleft : { title:'Veer Left', link:'ssd/veer', animation:'VeerLeftfromEightChainThru' },
veerright : { title:'Veer Right', link:'ssd/veer', animation:'VeerRightfromEightChainThru' },
couplescirculate : { title:'Couples Circulate', link:'ssd/circulate', animation:'CouplesCirculatefromRightHandTwoFacedLines' },
nameddancerscirculate : { title:'Ends Circulate', link:'ssd/circulate', animation:'EndsCirculatefromTwoFacedLines' },
couplestrade : { title:'Couples Trade', link:'ssd/trade', animation:'CouplesTradefromRightHandTwoFacedLines' },
nameddancerstrade : { title:'Girls Trade', link:'ssd/trade', animation:'GirlsTradefromRightHandTwoFacedLines' },
chaindowntheline : { title:'Chain Down the Line', link:'ssd/ladies_chain', animation:'ChainDowntheLinefromTwoFacedLines' },
rightandleftthru : { title:'Right and Left Thru', link:'ssd/right_and_left_thru', animation:'RightandLeftThrufromFacingCouples' },
flutterwheel : { title:'Flutterwheel', link:'ssd/flutterwheel', animation:'FlutterwheelfromFacingCouples' },
reverseflutterwheel : { title:'Reverse Flutterwheel', link:'ssd/flutterwheel', animation:'ReverseFlutterwheelfromFacingCouples' },
sweepaquarter : { title:'Flutterwheel and Sweep a Quarter', link:'ssd/sweep_a_quarter', animation:'FlutterwheelandSweepaQuarter' },
circletoaline : { title:'Circle to a Line', link:'ssd/circle_to_a_line', animation:'CircletoaLine' },
separatearound1toaline : { title:'Heads Pass Thru, Separate, Around 1 to a Line', link:'ssd/separate', animation:'HeadsPassThruSeparateAround1toaLine' },
separatearound2toaline : { title:'Heads Pass Thru, Separate, Around 2 to a Line', link:'ssd/separate', animation:'HeadsPassThruSeparateAround2toaLine' },
separatearound1andcomeintothemiddle : { title:'Heads Pass Thru, Separate, Around 1 and Come Into the Middle', link:'ssd/separate', animation:'HeadsPassThruSeparateAround1andComeIntotheMiddle' },
split2 : { title:'Split 2', link:'ssd/split_the_outside_couple', animation:'CentersSplittheOutsideCouple' },
wheelanddeal : { title:'Wheel and Deal', link:'ssd/wheel_and_deal', animation:'WheelandDealfromRightHandTwoFacedLines' },
wheelanddealfromlinesfacingout : { title:'Wheel and Deal', link:'ssd/wheel_and_deal', animation:'WheelandDealfromLinesFacingOut' },
doublepassthru : { title:'Double Pass Thru', link:'ssd/double_pass_thru', animation:'DoublePassThrufromDoublePassThru' },
firstcouplegoleftrightnextcouplegorightleft : { title:'First Couple Go Left, Next Couple Go Right', link:'ssd/first_couple_go', animation:'FirstCoupleGoLeftNextCoupleGoRight' },
steptoawave : { title:'Step to a Wave', link:'ssd/ocean_wave', animation:'SteptoaWavefromFacingCouples' },
balance : { title:'Balance', link:'ssd/ocean_wave', animation:'BalancefromRightHandWaves' },
alamostyle : { title:'Allemande Left in the Alamo Style', link:'ssd/alamo_style', animation:'AllemandeLeftintheAlamoStylefromStaticSquare' },
righthandtrade : { title:'Trade', link:'ssd/trade', animation:'TradefromRightHandWaves' },
lefthandtrade : { title:'Trade', link:'ssd/trade', animation:'TradefromLeftHandWaves' },
swingthru : { title:'Swing Thru', link:'ssd/swing_thru', animation:'SwingThrufromRightHandWaves' },
run : { title:'Boys Run', link:'ssd/run', animation:'BoysRunfromRightHandWaves' },
girlsrun : { title:'Girls Run', link:'ssd/run', animation:'GirlsRunfromRightHandWaves' },
crossrun : { title:'Girls Cross Run', link:'ssd/run', animation:'CentersCrossRunfromRightHandWaves' },
passtheocean : { title:'Pass the Ocean', link:'ssd/pass_the_ocean', animation:'PasstheOceanfromLines' },
extend : { title:'Extend', link:'ssd/extend', animation:'ExtendfromRightHand14Tag' },
zoom : { title:'Zoom', link:'ssd/zoom', animation:'ZoomfromDoublePassThru' },
centersin : { title:'Centers In', link:'ssd/centers_in', animation:'CentersInfromCompletedDoublePassThru' },
castoff34 : { title:'Cast Off 3/4', link:'ssd/cast_off_three_quarters', animation:'CastOffThreeQuartersfromLinesFacingOut' },
ferriswheel : { title:'Ferris Wheel', link:'ssd/ferris_wheel', animation:'FerrisWheelfromRightHandedTwoFacedLines' },
partnertrade : { title:'Partner Trade', link:'ssd/trade', animation:'PartnerTradefromLinesFacingOut' },
tradeby : { title:'Trade By', link:'ssd/trade_by', animation:'TradeByfromTradeBy' },
boxthegnat : { title:'Box the Gnat', link:'ssd/box_the_gnat', animation:'BoxtheGnatfromFacingCouples' },
hinge : { title:'Hinge', link:'ssd/hinge', animation:'HingefromRightHandWaves' },
coupleshinge : { title:'Hinge', link:'ssd/hinge', animation:'CouplesHingefromRightHandTwoFacedLines' },
touch14 : { title:'Touch 1/4', link:'ssd/touch_a_quarter', animation:'TouchaQuarterfromLines' },
all8circulate : { title:'All 8 Circulate', link:'ssd/circulate', animation:'All8CirculatefromRightHandWaves' },
singlefilecirculate : { title:'Single File Circulate', link:'ssd/circulate', animation:'ColumnCirculatefromRightHandColumns' },
tagtheline : { title:'Tag the Line', link:'ssd/tag', animation:'TagtheLinefromLinesFacingOut' },
halftag : { title:'Half Tag', link:'ssd/fraction_tag', animation:'HalfTagfromRightHandTwoFacedLines' },
splitcirculate : { title:'Split Circulate', link:'ssd/circulate', animation:'SplitCirculatefromRightHandWaves' },
boxcirculate : { title:'Centers Box Circulate', link:'ssd/circulate', animation:'CentersCirculatefromRightHandWaves' },
fold : { title:'Ends Fold', link:'ssd/fold', animation:'EndsFoldfromLinesFacingOut' },
crossfold : { title:'Ends Cross Fold', link:'ssd/fold', animation:'EndsCrossFoldfromLinesFacingOut' },
scootback : { title:'Scoot Back', link:'ssd/scoot_back', animation:'ScootBackfromRightHandWaves' },
recycle : { title:'Recycle', link:'ssd/recycle', animation:'RecyclefromRightHandWave' },
spinthetop : { title:'Spin the Top', link:'ms/spin_the_top',
  animation:'SpintheTopfromRightHandWave' },

  aceydeucey : { title:'Acey Deucey',link:'plus/acey_deucey',
    animation:'AceyDeuceyFromRightHandWaves'},
  cloverleaf : {
    title: 'Cloverleaf',
    link:'ms/cloverleaf',
    animation: 'CloverleaffromCompletedDoublePassThru'
  },
  pingpongcirculate : {
    title:'Ping Pong Circulate',
    link: 'plus/ping_pong_circulate',
    animation: 'PingPongCirculateFrommQuarterTag'
  },
  turnthru : {
    title:'Turn thru',
    link:'ms/turn_thru',
    animation: 'TurnThruFromFacingCouples'
  },
  passtothecenter : {
    title:'Pass to the Center',
    link:'ms/pass_to_the_center',
    animation:'PasstotheCenterfromEightChainThru'
  },
  spinchainthru : {
    title:'Spin Chain Thru',
    link:'ms/spin_chain_thru',
    animation:'SpinChainThrufromRightHandWaves'
  },
  scootanddodge : {
    title:'Scoot and Dodge',
    link:'a1/scoot_and_dodge',
    animation:'ScootandDodgefromRightHandBox'
  },
  pairoff : {
    title:'Heads Pair Off',
    link:'a1/pair_off',
    animation:'HeadsPairOff'
  },
  teacupchain : {
    title:'Teacup Chain',
    link:'plus/teacup_chain',
    animation:'TeacupChainfromStaticSquare'
  },
  dixiestyle : {
    title:'Dixie Style to a Wave',
    link:'ms/dixie_style',
    animation:'DixieStylefromFacingCouples'
  },
  walkaroundseesaw : {
    title: 'Walk Around the Corner, See Saw Your Partner',
    link:'b1/all_around_the_corner',
    animation:'WalkAroundtheCornerSeeSawYourPartner'
  },
  loadtheboat : {
    title:'Load the Boat',
    link:'plus/load_the_boat',
    animation:'LoadTheBoatfromFacingLines'
  },
  quarterthru : {
    title:'Quarter Thru',
    link:'a1/quarter_thru',
    animation:'QuarterThrufromRightHandWaves'
  },
  triplescoot : {
    title:'Triple Scoot',
    link:'plus/triple_scoot',
    animation:'TripleScootfromRightHandColumns'
  },
  track2 : {
    title:'Track 2',
    link:'plus/track_ii',
    animation:'Track 2'
  },
  grandquarterthru : {
    title:'Grand Quarter Thru',
    link:'a1/grand_quarter_thru',
    animation:'GrandQuarterThrufromRightHandColumns'
  },
  walkanddodge : {
    title: 'Walk and Dodge',
    link:'ms/walk_and_dodge',
    animation:'WalkandDodgefromRightHandWaves'
  },
  spinchainthegears : {
    title:'Spin Chain the Gears',
    link:'plus/spin_chain_the_gears',
    animation:'SpinChainTheGearsfromRightHandWaves'
  },
  grandswingthru : {
    title:'Grand Swing Thru',
    link:'plus/grand_swing_thru',
    animation:'GrandSwingThrufromRightHandTidalWave'
  },
  threequarterthru : {
    title:'Three Quarter Thru',
    link:'a1/quarter_thru',
    animation: '34ThrufromOceanWaves'
  },
  grandthreequarterthru : {
    title:'Grand Three Quarter Thru',
    link:'a1/grand_quarter_thru',
    animation:'Grand34ThrufromRightHandColumns'
  },
  roll : {
    title:'Hinge and Roll',
    link:'plus/anything_and_roll',
    animation:'HingeandRoll'
  },
  diamondcirculate : {
    title:'Diamond Circulate',
    link:'plus/diamond_circulate',
    animation:'DiamondCirculatefromRightHandDiamonds'
  },
  passthesea : {
    title:'Pass the Sea',
    link:'a1/pass_the_sea',
    animation:'PasstheSeafromLines'
  },
  flipthediamond : {
    title:'Flip the Diamond',
    link:'plus/flip_the_diamond',
    animation:'FliptheDiamondfromRightHandDiamonds'
  },
  followyourneighbor : {
    title:'Follow Your Neighbor',
    link:'plus/follow_your_neighbor',
    animation:'FollowYourNeighborfromRightHandWaves'
  },
  cutthediamond : {
    title:'Cut the Diamond',
    link:'plus/cut_the_diamond',
    animation:'CuttheDiamondfromRightHandDiamonds'
  },
  allemandethar : {
    title:'Allemande Left to an Allemande Thar',
    link:'ms/thar',
    animation:'AllemandeLefttoanAllemandeThar'
  },
  sliptheclutch : {
    title:'Slip the Clutch',
    link:'ms/slip_the_clutch',
    animation:'SliptheClutchfromThar'
  },
  tripletrade : {
    title:'Triple trade',
    link:'a1/triple_trade',
    animation:'TripleTradefromTidalWave'
  },
  shootthestar : {
    title:'Shoot the Star',
    link:'ms/shoot_the_star',
    animation:'ShoottheStarfromThar'
  },
  peeloff : {
    title:'Peel Off',
    link:'plus/peel_off',
    animation:'PeelOfffromCompletedDoublePassThru'
  },
  coordinate : {
    title:'Coordinate',
    link:'plus/coordinate',
    animation:'CoordinateFromRightHandColumns'
  },
  spread : {
    title:'Ferris Wheel and Spread',
    link:'plus/anything_and_spread',
    animation:'FerrisWheelandSpread'
  },
  fanthetop : {
    title:'Fan the Top',
    link:'plus/fan_the_top',
    animation:'FantheTopfromRightHandWave'
  },
  relaythedeucey : {
    title:'Relay the Deucey',
    link:'plus/relay_the_deucey',
    animation:'RelayTheDeucefromRightHandWaves'
  },
  partnertag : {
    title:'Partner Tag',
    link:'a1/partner_tag',
    animation:'PartnerTagfromFacingCouples'
  },
  dixiegrand : {
    title:'Dixie Grand',
    link:'plus/dixie_grand',
    animation:'DixieGrandfromDoublePassThru'
  },
  explodethewave : {
    title:'Explode the Wave',
    link:'plus/explode_the_wave',
    animation:'ExplodetheWavefromRightHandWaves'
  },
  crossfire : {
    title: 'Crossfire',
    link:'plus/crossfire',
    animation:'CrossfireFromRightHandTwoFacedLine'
  },
  explode : {
    title:'Explode and Slide Thru',
    link:'plus/explode_and_anything',
    animation:'ExplodeandSlideThru',
  },
  partnerhinge : {
    title:'Partner Hinge',
    link:'a1/partner_hinge',
    animation:'PartnerHingefromLines'
  },
  spinchainandexchangethegears : {
    title:'Spin Chain and Exchange the Gears',
    link:'plus/spin_chain_and_exchange_the_gears',
    animation:'SpinChainandExchangetheGearsfromRightHandWaves',
  },
  linearcycle : {
    title:'Linear Cycle',
    link:'plus/linear_cycle',
    animation:'LinearCyclefromRightHandWaves'
  },
  peelthetop : {
    title:'Peel the Top',
    link:'plus/peel_the_top',
    animation:'PeeltheTopfromRightHandColumns'
  },
  chaseright : {
    title:'Chase Right',
    link:'plus/chase_right',
    animation:'ChaseRightfromLinesFacingOut'
  },
  cloverand : {
    title:'Clover and Square Thru 2',
    link:'a1/clover_and_anything',
    animation:'CloverandSquareThru2'
  },
  tradethewave : {
    title:'Trade the Wave',
    link:'plus/trade_the_wave',
    animation:'TradetheWavefromRightHandWaves'
  },
  eightchainthru : {
    title:'Eight Chain 4',
    link:'ms/eight_chain_thru',
    animation:'EightChainFourfromEightChainThru'
  },
  all8spinthetop : {
    title:'All 8 Spin the Top',
    link:'plus/all_8_spin_the_top',
    animation:'All8SpintheTopfromWrongWayThar'
  },
  dopaso : {
    title:'Do Paso',
    link:'b1/do_paso',
    animation:'DoPaso'
  }




};

//  This routine resizes the web page so navigation buttons or other stuff on phones
//  doesn't cover our content
const resizeOps = () => {
   document.documentElement.style.setProperty("--vh", window.innerHeight * 0.01 + "px");
};

//  Called on startup and when a link in the index is tapped
function setAnimation(call) {
  //  Set the title, above the animation
  document.getElementById('animation-title').innerHTML = call.title;
  //  Load Taminations and tell it to show our animation
  document.getElementById('animation').src =
      'https://www.tamtwirlers.org/taminations/#?main=ANIMATIONS&link='
      + call.link + '&animname=' + call.animation + '&embed';
  //  Load the definition
  var lang = '';
  if (navigator.language.indexOf('de') >= 0)
    lang = '.lang-de';
  document.getElementById('definition').src =
      'https://www.tamtwirlers.org/taminations/#?main=ANIMATIONS&link=' +
      call.link + '&embed&definition';
  //  On small screens, show the animation frame
  showAnimation();
}

//  Routines to switch frames on small devices.
function showIndex() {
  document.getElementById('index-page').classList.remove('hide-page');
  document.getElementById('animation-page').classList.add('hide-page');
  document.getElementById('definition-page').classList.add('hide-page');
}
function showDefinition() {
  document.getElementById('index-page').classList.add('hide-page');
  document.getElementById('animation-page').classList.add('hide-page');
  document.getElementById('definition-page').classList.remove('hide-page');
}
function showAnimation() {
  document.getElementById('index-page').classList.add('hide-page');
  document.getElementById('animation-page').classList.remove('hide-page');
  document.getElementById('definition-page').classList.add('hide-page');
}

//  Called once after the web page is loaded
function startup() {
  //  Setup for auto-resizing when phone changes visible area
  resizeOps();
  window.addEventListener("resize", resizeOps);
  //  Default is to show the index
  showIndex();
  //  But if there's a search parameter that makes sense ...
  let q = location.search.substring(1).toLowerCase();
  if (q.length > 0) {
    //  Lookup the call
    let call = calls[q];
    if (call != undefined)
      //  And show that animation
      setAnimation(call);
  }

}
