import SwiftUI

struct MovieReleaseRow: View {
    var release: MovieRelease

    @State private var isShowingPopover = false

    var body: some View {
        linesStack
            .onTapGesture {
                isShowingPopover = true
            }
            .sheet(isPresented: $isShowingPopover) {
                MovieReleaseSheet(release: release)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
            }
    }

    var linesStack: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                Text(release.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }

            Group {
                HStack(spacing: 6) {
                    Text(release.qualityLabel)
                    Text("•")
                    Text(release.sizeLabel)
                    Text("•")
                    Text(release.ageLabel)
                }
                .lineLimit(1)
                .opacity(0.75)

                HStack(spacing: 6) {
                    Text(release.typeLabel)
                        .foregroundStyle(peerColor)
                        // .opacity(0.75)

                    Text("•").opacity(0.75)
                    Text(release.indexerLabel).opacity(0.75)

                    Spacer()

                    releaseIcon
                }.colorMultiply(.white)
                .lineLimit(1)
            }
            .font(.subheadline)
        }
    }

    var releaseIcon: some View {
        Group {
            if release.rejected {
                Image(systemName: "exclamationmark.triangle")
            } else if !release.indexerFlags.isEmpty {
                Image(systemName: "flag")
            }
        }
        .symbolVariant(.fill)
        .imageScale(.medium)
        .foregroundColor(.secondary)
    }

    var peerColor: any ShapeStyle {
        switch release.seeders ?? 0 {
        case 50...: .green
        case 10..<50: .blue
        case 1..<10: .orange
        default: .red
        }
    }
}
