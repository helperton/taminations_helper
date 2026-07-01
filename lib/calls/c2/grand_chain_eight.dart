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

import '../../animated_call.dart';
import '../../common_dart.dart';
import '../../moves.dart';

  final List<AnimatedCall> GrandChainEight = [

    AnimatedCall('Grand Chain Eight',
      formation:Formation('', dancers:[
        Dancer.fromData(gender:Gender.BOY,x:-2,y:3,angle:0),
        Dancer.fromData(gender:Gender.GIRL,x:-2,y:-3,angle:0),
  ]),
      from:'Ends Facing Only',isPerimeter:true,noDisplay: true,
      paths:[
          ExtendLeft.changeBeats(2).scale(2.0,0.5) +
          LeadRight.changeBeats(3).scale(2.5,2.5) +
          QuarterLeft.skew(1.0,0.0) +
          QuarterLeft +
          BackHingeRight.scale(1.0,0.5),

          ExtendLeft.changeBeats(2).scale(2.0,0.5) +
          LeadLeft.changeBeats(4.5).scale(3.5,2.5) +
          HingeLeft.changeBeats(3).scale(1.0,0.5)
      ]),

    AnimatedCall('Grand Chain Eight',
      formation:Formation('Double Pass Thru'),
      from:'Double Pass Thru',
      paths:[
        Stand.changehands(Hands.RIGHT) +
            Forward_1p5.changeBeats(1) +
            UmTurnLeft.changeBeats(1.6).changehands(Hands.GRIPLEFT).skew(0.333,0.333) +
            QuarterLeft.changeBeats(0.8).changehands(Hands.GRIPLEFT).skew(-0.167,-0.167),

        Stand.changehands(Hands.LEFT) +
            ExtendRight.scale(1.5,2) +
            HingeLeft.changeBeats(2.4).changehands(Hands.GRIPLEFT).scale(0.5,1.5),

        ExtendLeft.scale(1,0.5) +
            ExtendRight.scale(1.5,0.5) +
            UmTurnLeft.changeBeats(1.6).changehands(Hands.GRIPLEFT).skew(1,0.333) +
            QuarterLeft.changeBeats(0.8).changehands(Hands.GRIPLEFT).skew(-0.5,-0.167),

        ExtendLeft.scale(1,0.5) +
            ExtendRight.scale(1.5,2.5) +
            HingeLeft.changeBeats(2.4).changehands(Hands.GRIPLEFT).scale(1.5,1.5),
      ]),

    AnimatedCall('Grand Chain Eight',
      formation:Formation('', dancers:[
        Dancer.fromData(gender:Gender.BOY,x:3,y:2,angle:270),
        Dancer.fromData(gender:Gender.GIRL,x:1,y:2,angle:270),
        Dancer.fromData(gender:Gender.BOY,x:-1,y:2,angle:270),
        Dancer.fromData(gender:Gender.GIRL,x:-3,y:2,angle:270),
  ]),
      from:'Lines',
      paths:[
          ExtendLeft.changeBeats(2).scale(2.0,0.5) +
              LeadRight.changeBeats(4.5).scale(2.5,3.5) +
              UmTurnLeft.changehands(Hands.GRIPLEFT).changeBeats(1.6).skew(0.667,0.333) +
              QuarterLeft.changehands(Hands.GRIPLEFT).changeBeats(0.8).skew(-0.333,-0.167),

          ExtendLeft.changeBeats(2).scale(2.0,0.5) +
              LeadRight.changeBeats(4.5).scale(0.5,1.5) +
              HingeLeft.changehands(Hands.GRIPLEFT).changeBeats(2.4).scale(1,0.5),

          ExtendLeft.changeBeats(2).scale(2.0,0.5) +
              LeadLeft.changeBeats(4.5).scale(1.5,0.5) +
              UmTurnLeft.changehands(Hands.GRIPLEFT).changeBeats(1.6).skew(0.667,0.333) +
              QuarterLeft.changehands(Hands.GRIPLEFT).changeBeats(0.8).skew(-0.333,-0.167),

          ExtendLeft.changeBeats(2).scale(2.0,0.5) +
              LeadLeft.changeBeats(4.5).scale(3.5,2.5) +
              HingeLeft.changehands(Hands.GRIPLEFT).changeBeats(2.4).scale(1,0.5),
      ]),

    AnimatedCall('Grand Chain Eight',
      formation:Formation('Eight Chain Thru'),
      from:'Eight Chain Thru',
      paths:[
          ExtendLeft.scale(1.0,0.5) +
          ExtendRight.changeBeats(2).scale(2.0,0.5) +
              UmTurnLeft.changehands(Hands.GRIPLEFT).changeBeats(2).skew(0.667,0) +
              QuarterLeft.changehands(Hands.GRIPLEFT).changeBeats(1).skew(-0.333,0),

          ExtendLeft.scale(1.0,0.5) +
          ExtendRight.changeBeats(2).scale(2.0,1.5) +
          HingeLeft.changehands(Hands.GRIPLEFT).changeBeats(3),

          ExtendLeft.scale(1.0,0.5) +
          ExtendRight.changeBeats(2).scale(1.0,0.5) +
          BeauWheel,

          ExtendLeft.scale(1.0,0.5) +
          ExtendRight.changeBeats(2).scale(1.0,0.5) +
          BelleWheel
      ]),

    AnimatedCall('Grand Chain Eight',
      formation:Formation('Ocean Waves RH BGGB'),
      from:'Right-Hand Waves',
      paths:[
          ExtendRight.changeBeats(2).scale(2.0,2.0) +
              UmTurnLeft.changehands(Hands.GRIPLEFT).changeBeats(2).skew(0.667,0) +
              QuarterLeft.changehands(Hands.GRIPLEFT).changeBeats(1).skew(-0.333,0),

          Forward.changeBeats(2).scale(1.0,0.5) +
          BelleWheel,

          ExtendRight.changeBeats(2).scale(2.0,1.0) +
          HingeLeft.changeBeats(3).changehands(Hands.GRIPLEFT),

          ExtendRight.changeBeats(2).scale(1.0,2.0) +
          BeauWheel
      ]),

    AnimatedCall('Grand Chain Eight',
        formation:Formation('Quarter Tag'),
        from:'Quarter Tag',
        paths:[
              Forward_1p5.changeBeats(1) +
              UmTurnLeft.changeBeats(1.6).changehands(Hands.GRIPLEFT).skew(0.333,0.333) +
              QuarterLeft.changeBeats(0.8).changehands(Hands.GRIPLEFT).skew(-0.167,-0.167),

              ExtendRight.scale(1.5,2) +
              HingeLeft.changeBeats(2.4).changehands(Hands.GRIPLEFT).scale(0.5,1.5),

              ExtendRight.scale(1.5,2) +
              UmTurnLeft.changeBeats(1.6).changehands(Hands.GRIPLEFT).skew(1,0.333) +
              QuarterLeft.changeBeats(0.8).changehands(Hands.GRIPLEFT).skew(-0.5,-0.167),

              ExtendRight.scale(1.5,2) +
              HingeLeft.changeBeats(2.4).changehands(Hands.GRIPLEFT).scale(1.5,1.5),
        ]),

    AnimatedCall('Grand Chain Eight',
      formation:Formation('Tidal Wave RH BGGB'),
      from:'Tidal Wave',
      paths:[
        LeadRight.changeBeats(4.5).scale(2.5,3.5) +
            UmTurnLeft.changehands(Hands.GRIPLEFT).changeBeats(1.6).skew(0.667,0.333) +
            QuarterLeft.changehands(Hands.GRIPLEFT).changeBeats(0.8).skew(-0.333,-0.167),

        LeadLeft.changeBeats(4.5).scale(3.5,2.5) +
            HingeLeft.changehands(Hands.GRIPLEFT).changeBeats(2.4).scale(1,0.5),

        LeadRight.changeBeats(4.5).scale(0.5,1.5) +
            HingeLeft.changehands(Hands.GRIPLEFT).changeBeats(2.4).scale(1,0.5),

        LeadLeft.changeBeats(4.5).scale(1.5,0.5) +
            UmTurnLeft.changehands(Hands.GRIPLEFT).changeBeats(1.6).skew(0.667,0.333) +
            QuarterLeft.changehands(Hands.GRIPLEFT).changeBeats(0.8).skew(-0.333,-0.167),

      ]),

    AnimatedCall('Split Grand Chain Eight',
      formation:Formation('T-Bone ULRU'),
      from:'T-Bones, Ends Facing',
      paths:[
          ExtendLeft.scale(1.0,0.5) +
              LeadRight.changeBeats(2).scale(1,2) +
              UmTurnLeft.changeBeats(1.6).changehands(Hands.GRIPLEFT).skew(0.333,0.333) +
              QuarterLeft.changeBeats(0.8).changehands(Hands.GRIPLEFT).skew(-0.167,-0.167),

          Stand.changeBeats(1) +
              ExtendRight.changeBeats(2).scale(0.5,2) +
              HingeLeft.changeBeats(2.4).changehands(Hands.GRIPLEFT).scale(1.5,1.5),

        Stand.changeBeats(1) +
              Forwardp5.changeBeats(2) +
              UmTurnLeft.changeBeats(1.6).changehands(Hands.GRIPLEFT).skew(1,0.333) +
              QuarterLeft.changeBeats(0.8).changehands(Hands.GRIPLEFT).skew(-0.5,-0.167),

          ExtendLeft.scale(1.0,0.5) +
              LeadLeft.changeBeats(2).scale(3,1) +
              HingeLeft.changeBeats(2.4).changehands(Hands.GRIPLEFT).scale(0.5,1.5),
      ]),

    AnimatedCall('Split Grand Chain Eight',
      formation:Formation('T-Bone RUUL'),
      from:'T-Bones, Centers Facing',
      paths:[
          Stand.changeBeats(1) +
              ExtendRight.changeBeats(2).scale(1.5,2) +
              HingeLeft.changeBeats(2.4).changehands(Hands.GRIPLEFT).scale(0.5,1.5),

          Stand.changeBeats(1) +
              Forward_1p5.changeBeats(2) +
              UmTurnLeft.changeBeats(1.6).changehands(Hands.GRIPLEFT).skew(0.333,0.333) +
              QuarterLeft.changeBeats(0.8).changehands(Hands.GRIPLEFT).skew(-0.167,-0.167),

          ExtendLeft.scale(1.0,0.5) +
              Forward_1p5.changeBeats(1) +
              QuarterLeft.changeBeats(1).skew(1.5, 0) +
              HingeLeft.changeBeats(2.4).changehands(Hands.GRIPLEFT).scale(1.5,1.5),

        ExtendLeft.scale(1.0,0.5) +
              LeadRight.changeBeats(2) +
            UmTurnLeft.changeBeats(1.6).changehands(Hands.GRIPLEFT).skew(1,0.333) +
            QuarterLeft.changeBeats(0.8).changehands(Hands.GRIPLEFT).skew(-0.5,-0.167),

      ]),

    AnimatedCall('Split Grand Chain Eight',
      formation:Formation('T-Bone RLUU'),
      from:'T-Bones 3',
      paths:[
          ExtendLeft.scale(1.0,0.5) +
              LeadLeft.changeBeats(2).scale(1.5,0.5) +
              HingeLeft.changehands(Hands.GRIPLEFT).changeBeats(2.4).scale(1,0.5),

        ExtendLeft.scale(1.0,0.5) +
              LeadRight.changeBeats(2).scale(0.5,1.5) +
            UmTurnLeft.changehands(Hands.GRIPLEFT).changeBeats(1.6).skew(0.667,0.333) +
            QuarterLeft.changehands(Hands.GRIPLEFT).changeBeats(0.8).skew(-0.333,-0.167),


          Stand.changeBeats(1) +
              ExtendRight.changeBeats(2).scale(1,0.5) +
              UmTurnLeft.changehands(Hands.GRIPLEFT).changeBeats(1.6).skew(0.667,0.333) +
              QuarterLeft.changehands(Hands.GRIPLEFT).changeBeats(0.8).skew(-0.333,-0.167),

          Stand.changeBeats(1) +
              ExtendRight.changeBeats(2).scale(1,0.5) +
              HingeLeft.changehands(Hands.GRIPLEFT).changeBeats(2.4).scale(1,0.5)
      ]),

    AnimatedCall('Split Grand Chain Eight',
      formation:Formation('T-Bone UURL'),
      from:'T-Bones 4',
      paths:[
        Stand.changeBeats(1) +
            ExtendRight.changeBeats(2).scale(1,0.5) +
            UmTurnLeft.changehands(Hands.GRIPLEFT).changeBeats(1.6).skew(0.667,0.333) +
            QuarterLeft.changehands(Hands.GRIPLEFT).changeBeats(0.8).skew(-0.333,-0.167),


        Stand.changeBeats(1) +
            ExtendRight.changeBeats(2).scale(1,0.5) +
            HingeLeft.changehands(Hands.GRIPLEFT).changeBeats(2.4).scale(1,0.5),

        ExtendLeft.scale(1.0,0.5) +
            LeadLeft.changeBeats(2).scale(1.5,0.5) +
            HingeLeft.changehands(Hands.GRIPLEFT).changeBeats(2.4).scale(1,0.5),

        ExtendLeft.scale(1.0,0.5) +
            LeadRight.changeBeats(2).scale(0.5,1.5) +
            UmTurnLeft.changehands(Hands.GRIPLEFT).changeBeats(1.6).skew(0.667,0.333) +
            QuarterLeft.changehands(Hands.GRIPLEFT).changeBeats(0.8).skew(-0.333,-0.167),
      ]),

    AnimatedCall('Heads Start Split Grand Chain Eight',
      formation:Formation('Static Square'),
      group:' ',
      paths:[
        Forward_2 +
            ExtendLeft.scale(1.0,0.5) +
            Forward_1p5.changeBeats(1) +
            QuarterLeft.changeBeats(1).skew(1.5, 0) +
            HingeLeft.changeBeats(2.4).changehands(Hands.GRIPLEFT).scale(1.5,1.5),

        Forward_2 +
            ExtendLeft.scale(1.0,0.5) +
            LeadRight.changeBeats(2) +
            UmTurnLeft.changeBeats(1.6).changehands(Hands.GRIPLEFT).skew(1,0.333) +
            QuarterLeft.changeBeats(0.8).changehands(Hands.GRIPLEFT).skew(-0.5,-0.167),

        Stand.changeBeats(3) +
            Forward_1p5.changeBeats(2) +
            UmTurnLeft.changeBeats(1.6).changehands(Hands.GRIPLEFT).skew(0.333,0.333) +
            QuarterLeft.changeBeats(0.8).changehands(Hands.GRIPLEFT).skew(-0.167,-0.167),

        Stand.changeBeats(3) +
            ExtendRight.changeBeats(2).scale(1.5,2) +
            HingeLeft.changeBeats(2.4).changehands(Hands.GRIPLEFT).scale(0.5,1.5)
      ]),

    AnimatedCall('Sides Start Split Grand Chain Eight',
      formation:Formation('Static Square'),
      group:' ',noDisplay: true,
      paths:[
        Stand.changeBeats(3) +
            Forward_1p5.changeBeats(2) +
            UmTurnLeft.changeBeats(1.6).changehands(Hands.GRIPLEFT).skew(0.333,0.333) +
            QuarterLeft.changeBeats(0.8).changehands(Hands.GRIPLEFT).skew(-0.167,-0.167),

        Stand.changeBeats(3) +
            ExtendRight.changeBeats(2).scale(1.5,2) +
            HingeLeft.changeBeats(2.4).changehands(Hands.GRIPLEFT).scale(0.5,1.5),

        Forward_2 +
            ExtendLeft.scale(1.0,0.5) +
            Forward_1p5.changeBeats(1) +
            QuarterLeft.changeBeats(1).skew(1.5, 0) +
            HingeLeft.changeBeats(2.4).changehands(Hands.GRIPLEFT).scale(1.5,1.5),

        Forward_2 +
            ExtendLeft.scale(1.0,0.5) +
            LeadRight.changeBeats(2) +
            UmTurnLeft.changeBeats(1.6).changehands(Hands.GRIPLEFT).skew(1,0.333) +
            QuarterLeft.changeBeats(0.8).changehands(Hands.GRIPLEFT).skew(-0.5,-0.167),


      ]),
  ];

