import KingdomCore
import SwiftUI

// The five companions in cut paper, each drawn in a 200 x 200 box and scaled by SparkleView.
// Charter v1.3: each must read in silhouette. The unicorn has a long neck, four legs, a mane, a tail and a horn.

struct CompanionArt: View {
    let companion: Companion
    var mood: SparkleView.Mood = .happy

    var body: some View {
        ZStack {
            switch companion {
            case .unicorn: UnicornArt(mood: mood)
            case .superhero: SuperheroArt(mood: mood)
            case .princess: PrincessArt(mood: mood)
            case .monster: MonsterArt(mood: mood)
            case .gnome: GnomeArt(mood: mood)
            }
            if mood == .sleeping {
                Text("z z z").font(Theme.title(22)).foregroundStyle(Theme.clay)
                    .position(x: 176, y: 24)
            }
        }
        .frame(width: 200, height: 200)
    }
}

/// A path from points in the 200 x 200 box.
private func poly(_ pts: [(CGFloat, CGFloat)]) -> Path {
    var p = Path()
    guard let f = pts.first else { return p }
    p.move(to: CGPoint(x: f.0, y: f.1))
    for q in pts.dropFirst() { p.addLine(to: CGPoint(x: q.0, y: q.1)) }
    p.closeSubpath()
    return p
}

/// Eyes for every companion: open, looking up (thinking) or closed (sleeping).
private struct Eye: View {
    var mood: SparkleView.Mood
    var r: CGFloat = 5
    var body: some View {
        switch mood {
        case .sleeping: Capsule().fill(Theme.ink).frame(width: r * 2.4, height: 2.5)
        case .thinking: Circle().fill(Theme.ink).frame(width: r * 2, height: r * 2).offset(x: 1, y: -2)
        case .happy:
            Circle().fill(Theme.ink).frame(width: r * 2, height: r * 2)
                .overlay(Circle().fill(Color.white).frame(width: r * 0.7, height: r * 0.7).offset(x: r * 0.35, y: -r * 0.35))
        }
    }
}

// MARK: Unicorn

struct UnicornArt: View {
    var mood: SparkleView.Mood
    var body: some View {
        let coat = Theme.card
        let line = Theme.tan
        ZStack {
            // Tail: three paper curls
            Path { p in
                p.move(to: CGPoint(x: 48, y: 104))
                p.addCurve(to: CGPoint(x: 22, y: 160), control1: CGPoint(x: 20, y: 104), control2: CGPoint(x: 38, y: 140))
                p.addCurve(to: CGPoint(x: 52, y: 118), control1: CGPoint(x: 44, y: 150), control2: CGPoint(x: 40, y: 126))
                p.closeSubpath()
            }.fill(Theme.rose).paperCut(0.5)
            Path { p in
                p.move(to: CGPoint(x: 50, y: 110))
                p.addCurve(to: CGPoint(x: 34, y: 150), control1: CGPoint(x: 34, y: 116), control2: CGPoint(x: 40, y: 136))
                p.addCurve(to: CGPoint(x: 54, y: 120), control1: CGPoint(x: 48, y: 140), control2: CGPoint(x: 46, y: 126))
                p.closeSubpath()
            }.fill(Theme.ochre)
            // Back legs (darker, behind)
            ForEach([62, 82] as [CGFloat], id: \.self) { x in
                RoundedRectangle(cornerRadius: 5).fill(line).frame(width: 13, height: 58).position(x: x, y: 158)
                RoundedRectangle(cornerRadius: 3).fill(Theme.clay).frame(width: 13, height: 8).position(x: x, y: 186)
            }
            // Body
            Ellipse().fill(coat).frame(width: 104, height: 58).position(x: 88, y: 122).paperCut(0.6)
            // Front legs
            ForEach([108, 126] as [CGFloat], id: \.self) { x in
                RoundedRectangle(cornerRadius: 5).fill(coat).frame(width: 13, height: 60).position(x: x, y: 158)
                RoundedRectangle(cornerRadius: 3).fill(Theme.clay).frame(width: 13, height: 8).position(x: x, y: 187)
            }
            // Long neck
            poly([(108, 112), (124, 62), (148, 56), (142, 118)]).fill(coat)
            // Head with a long muzzle, nose to the right
            Path { p in
                p.move(to: CGPoint(x: 126, y: 60))
                p.addQuadCurve(to: CGPoint(x: 160, y: 40), control: CGPoint(x: 136, y: 36))
                p.addQuadCurve(to: CGPoint(x: 186, y: 72), control: CGPoint(x: 186, y: 50))
                p.addQuadCurve(to: CGPoint(x: 168, y: 84), control: CGPoint(x: 184, y: 86))
                p.addQuadCurve(to: CGPoint(x: 134, y: 78), control: CGPoint(x: 150, y: 82))
                p.closeSubpath()
            }.fill(coat).paperCut(0.4)
            Circle().fill(Theme.tan).frame(width: 5, height: 5).position(x: 178, y: 70) // nostril
            // Ear
            poly([(140, 44), (146, 22), (154, 42)]).fill(coat)
            poly([(143, 41), (147, 28), (151, 40)]).fill(Theme.rose.opacity(0.6))
            // Horn: a gold spiral cone
            poly([(152, 40), (176, 6), (162, 44)]).fill(Theme.sun).paperCut(0.3)
            Path { p in
                p.move(to: CGPoint(x: 156, y: 34)); p.addLine(to: CGPoint(x: 163, y: 36))
                p.move(to: CGPoint(x: 160, y: 26)); p.addLine(to: CGPoint(x: 167, y: 27))
                p.move(to: CGPoint(x: 165, y: 18)); p.addLine(to: CGPoint(x: 170, y: 18))
            }.stroke(Theme.ochre, lineWidth: 2)
            // Mane along the neck: paper curls in rose and ochre
            ForEach(0..<5, id: \.self) { i in
                Circle().fill(i.isMultiple(of: 2) ? Theme.rose : Theme.ochre)
                    .frame(width: 18, height: 18)
                    .position(x: 132 - CGFloat(i) * 5, y: 44 + CGFloat(i) * 15)
            }
            Eye(mood: mood, r: 4.5).position(x: 160, y: 56)
            Circle().fill(Theme.rose.opacity(0.35)).frame(width: 10, height: 10).position(x: 168, y: 70)
        }
    }
}

// MARK: Superhero (made up: Nova, with a star on the chest and a cape)

struct SuperheroArt: View {
    var mood: SparkleView.Mood
    var body: some View {
        let skin = Color(hex: 0xC98B62)
        ZStack {
            // Cape behind
            poly([(70, 70), (130, 70), (156, 186), (44, 186)]).fill(Theme.clay).paperCut(0.6)
            // Legs and boots
            RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0x3F5A7A)).frame(width: 20, height: 56).position(x: 88, y: 158)
            RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0x3F5A7A)).frame(width: 20, height: 56).position(x: 112, y: 158)
            RoundedRectangle(cornerRadius: 5).fill(Theme.sun).frame(width: 24, height: 14).position(x: 88, y: 186)
            RoundedRectangle(cornerRadius: 5).fill(Theme.sun).frame(width: 24, height: 14).position(x: 112, y: 186)
            // Body suit
            RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0x4F7AA6)).frame(width: 62, height: 70).position(x: 100, y: 112).paperCut(0.4)
            StarShape().fill(Theme.sun).frame(width: 30, height: 30).position(x: 100, y: 108)
            // Arms raised in a power pose
            Capsule().fill(Color(hex: 0x4F7AA6)).frame(width: 14, height: 46).rotationEffect(.degrees(35)).position(x: 62, y: 94)
            Capsule().fill(Color(hex: 0x4F7AA6)).frame(width: 14, height: 46).rotationEffect(.degrees(-35)).position(x: 138, y: 94)
            Circle().fill(skin).frame(width: 16, height: 16).position(x: 50, y: 76)
            Circle().fill(skin).frame(width: 16, height: 16).position(x: 150, y: 76)
            // Head, hair, mask
            Circle().fill(skin).frame(width: 52, height: 52).position(x: 100, y: 56).paperCut(0.3)
            Path { p in
                p.addArc(center: CGPoint(x: 100, y: 52), radius: 27, startAngle: .degrees(190), endAngle: .degrees(350), clockwise: false)
            }.fill(Theme.ink)
            Capsule().fill(Theme.poppy).frame(width: 50, height: 14).position(x: 100, y: 58)
            HStack(spacing: 12) { Eye(mood: mood, r: 3.5); Eye(mood: mood, r: 3.5) }.position(x: 100, y: 58)
            Capsule().fill(Theme.ink).frame(width: 12, height: 3).position(x: 100, y: 72)
        }
    }
}

// MARK: Princess (Lumi, a different princess from her own hero)

struct PrincessArt: View {
    var mood: SparkleView.Mood
    var body: some View {
        let skin = Color(hex: 0xE2B48F)
        ZStack {
            // Hair behind
            Ellipse().fill(Theme.ochre).frame(width: 64, height: 80).position(x: 100, y: 70).paperCut(0.4)
            // Gown: a wide paper bell
            poly([(80, 92), (120, 92), (156, 186), (44, 186)]).fill(Theme.sage).paperCut(0.6)
            poly([(86, 120), (114, 120), (130, 186), (70, 186)]).fill(Theme.sagePale)
            Capsule().fill(skin).frame(width: 10, height: 40).rotationEffect(.degrees(20)).position(x: 76, y: 114)
            Capsule().fill(skin).frame(width: 10, height: 40).rotationEffect(.degrees(-20)).position(x: 124, y: 114)
            // Head and crown
            Circle().fill(skin).frame(width: 46, height: 46).position(x: 100, y: 64)
            poly([(80, 42), (86, 24), (93, 38), (100, 20), (107, 38), (114, 24), (120, 42)]).fill(Theme.sun).paperCut(0.3)
            Circle().fill(Theme.rose).frame(width: 6, height: 6).position(x: 100, y: 32)
            HStack(spacing: 12) { Eye(mood: mood, r: 3.5); Eye(mood: mood, r: 3.5) }.position(x: 100, y: 64)
            Capsule().fill(Theme.rose).frame(width: 10, height: 3).position(x: 100, y: 76)
        }
    }
}

// MARK: Cute monster (Bloop: round, one big eye, two little horns)

struct MonsterArt: View {
    var mood: SparkleView.Mood
    var body: some View {
        let fur = Color(hex: 0x6FA39A)
        ZStack {
            poly([(70, 52), (78, 22), (88, 50)]).fill(Theme.sun)
            poly([(112, 50), (122, 22), (130, 52)]).fill(Theme.sun)
            // Feet
            Ellipse().fill(Color(hex: 0x4E8078)).frame(width: 36, height: 18).position(x: 78, y: 182)
            Ellipse().fill(Color(hex: 0x4E8078)).frame(width: 36, height: 18).position(x: 122, y: 182)
            // Round body with a scalloped belly
            Ellipse().fill(fur).frame(width: 130, height: 140).position(x: 100, y: 110).paperCut(0.6)
            Ellipse().fill(Color(hex: 0xA9CFC6)).frame(width: 74, height: 64).position(x: 100, y: 138)
            // Little arms
            Capsule().fill(fur).frame(width: 18, height: 40).rotationEffect(.degrees(30)).position(x: 38, y: 116)
            Capsule().fill(fur).frame(width: 18, height: 40).rotationEffect(.degrees(-30)).position(x: 162, y: 116)
            // One big eye
            Circle().fill(Theme.card).frame(width: 52, height: 52).position(x: 100, y: 78).paperCut(0.3)
            Eye(mood: mood, r: 10).position(x: 100, y: 80)
            // Smile with two teeth
            Path { p in
                p.move(to: CGPoint(x: 82, y: 108))
                p.addQuadCurve(to: CGPoint(x: 118, y: 108), control: CGPoint(x: 100, y: 124))
            }.stroke(Theme.ink, lineWidth: 3)
            Rectangle().fill(Theme.card).frame(width: 6, height: 7).position(x: 94, y: 113)
            Rectangle().fill(Theme.card).frame(width: 6, height: 7).position(x: 106, y: 113)
        }
    }
}

// MARK: Gnome (Pip: tall red hat, big white beard, round nose)

struct GnomeArt: View {
    var mood: SparkleView.Mood
    var body: some View {
        ZStack {
            // Body and boots
            poly([(72, 110), (128, 110), (142, 178), (58, 178)]).fill(Color(hex: 0x4F6D8A)).paperCut(0.5)
            Ellipse().fill(Theme.woodDark).frame(width: 34, height: 16).position(x: 80, y: 184)
            Ellipse().fill(Theme.woodDark).frame(width: 34, height: 16).position(x: 120, y: 184)
            Rectangle().fill(Theme.wood).frame(width: 76, height: 8).position(x: 100, y: 150)
            // Face
            Circle().fill(Color(hex: 0xE8BFA0)).frame(width: 50, height: 50).position(x: 100, y: 82)
            // Beard
            Path { p in
                p.move(to: CGPoint(x: 72, y: 88))
                p.addQuadCurve(to: CGPoint(x: 100, y: 150), control: CGPoint(x: 74, y: 140))
                p.addQuadCurve(to: CGPoint(x: 128, y: 88), control: CGPoint(x: 126, y: 140))
                p.addQuadCurve(to: CGPoint(x: 72, y: 88), control: CGPoint(x: 100, y: 104))
            }.fill(Theme.card).paperCut(0.4)
            // Tall pointed hat
            poly([(66, 70), (134, 70), (108, 6)]).fill(Theme.poppy).paperCut(0.4)
            Capsule().fill(Theme.clay).frame(width: 74, height: 10).position(x: 100, y: 70)
            HStack(spacing: 14) { Eye(mood: mood, r: 3.5); Eye(mood: mood, r: 3.5) }.position(x: 100, y: 80)
            Circle().fill(Theme.rose).frame(width: 16, height: 16).position(x: 100, y: 92)
        }
    }
}
