import SwiftUI
import UIKit

/// Blur natif via UIVisualEffectView (marche sur device, iOS récents).
struct VisualEffectBlur: UIViewRepresentable {
    let style: UIBlurEffect.Style  // ex: .systemUltraThinMaterial

    func makeUIView(context: Context) -> UIVisualEffectView {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: style))
        v.isUserInteractionEnabled = false
        v.backgroundColor = .clear
        return v
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

/// Fond "glass" prêt à l’emploi pour un widget (sans dépendre des nouvelles APIs).
struct GlassBackground: View {
    var cornerRadius: CGFloat = 22
    /// Optionnel : très légère teinte au-dessus du blur (0 = pas de teinte).
    var tint: Color = .clear
    var tintOpacity: Double = 0.08

    var body: some View {
        VisualEffectBlur(style: .systemUltraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                // Liseré doux pour mieux “décoller” sur fonds sombres
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 0.8)
            )
            .overlay(
                // Voile de teinte subtil si demandé
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint.opacity(tint == .clear ? 0 : tintOpacity))
            )
    }
}
