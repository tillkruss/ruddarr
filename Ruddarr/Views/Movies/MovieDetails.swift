import SwiftUI

struct MovieDetails: View {
    var movie: Movie

    @State private var descriptionTruncated = true

    @EnvironmentObject var settings: AppSettings
    @Environment(RadarrInstance.self) private var instance

    var body: some View {
        VStack(alignment: .leading) {
            // MARK: overview
            MovieDetailsOverview(movie: movie)
                .padding(.bottom)

            // MARK: description
            description
                .padding(.bottom)

            // MARK: details
            Grid(alignment: .leading) {
                detailsRow("Status", value: movie.status.label)

                if let studio = movie.studio, !studio.isEmpty {
                    detailsRow("Studio", value: studio)
                }

                if !movie.genres.isEmpty {
                    detailsRow("Genre", value: movie.genreLabel)
                }

                if movie.isDownloaded {
                    detailsRow("Video", value: videoQuality)
                    detailsRow("Audio", value: audioQuality)
                }
            }.padding(.bottom)

            // MARK: actions
            actions
                .padding(.bottom)

            // MARK: information
            information
                .padding(.bottom)
        }
    }

    var description: some View {
        HStack(alignment: .top) {
            Text(movie.overview!)
                .font(.callout)
                .transition(.slide)
                .lineLimit(descriptionTruncated ? 4 : nil)
                .textSelection(.enabled)
                .onTapGesture {
                    withAnimation { descriptionTruncated.toggle() }
                }

            Spacer()
        }
    }

    var actions: some View {
        HStack(spacing: 24) {
            Button {
                Task { @MainActor in
                    guard await instance.movies.command(movie, command: .automaticSearch) else {
                        return
                    }

                    dependencies.toast.show(.searchQueued)
                }
            } label: {
                ButtonLabel(text: "Automatic", icon: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .allowsHitTesting(!instance.movies.isWorking)

            NavigationLink(value: MoviesView.Path.releases(movie.id), label: {
                ButtonLabel(text: "Interactive", icon: "person.fill")
                    .frame(maxWidth: .infinity)
            })
            .buttonStyle(.bordered)
            .tint(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    var information: some View {
        Section(
            header: Text("Information")
                .font(.title2)
                .fontWeight(.bold)
        ) {
            VStack(spacing: 12) {
                informationRow("Quality Profile", value: qualityProfile)
                Divider()
                informationRow("Minimum Availability", value: movie.minimumAvailability.label)
                Divider()
                informationRow("Root Folder", value: movie.rootFolderPath ?? "")

                if movie.isDownloaded {
                    Divider()
                    informationRow("Size", value: movie.sizeOnDisk == nil ? "" : movie.sizeLabel)
                }

                if let inCinemas = movie.inCinemas {
                    Divider()
                    informationRow("In Cinemas", value: inCinemas.formatted(.dateTime.day().month().year()))
                }

                if let physicalRelease = movie.physicalRelease {
                    Divider()
                    informationRow("Physical Release", value: physicalRelease.formatted(.dateTime.day().month().year()))
                }

                if let digitalRelease = movie.digitalRelease {
                    Divider()
                    informationRow("Digital Release", value: digitalRelease.formatted(.dateTime.day().month().year()))
                }
            }
        }
        .font(.callout)
    }

    var videoQuality: String {
        var label = ""
        var codec = ""

        if let resolution = movie.movieFile?.quality.quality.resolution {
            label = "\(resolution)p"
        }

        if let videoCodec = movie.movieFile?.mediaInfo.videoCodec {
            codec = videoCodec
        }

        if label.isEmpty {
            label = "Unknown"
        }

        return "\(label) (\(codec))"
    }

    var audioQuality: String {
        var languages: [String] = []
        var codec = ""

        if let langs = movie.movieFile?.languages {
            languages = langs
                .filter { $0.name != nil }
                .map { $0.name ?? "Unknown" }
        }

        if let audioCodec = movie.movieFile?.mediaInfo.audioCodec {
            codec = audioCodec
        }

        if languages.isEmpty {
            languages.append("Unknown")
        }

        let languageList = languages.joined(separator: ", ")

        return "\(languageList) (\(codec))"
    }

    var qualityProfile: String {
        instance.qualityProfiles.first(
            where: { $0.id == movie.qualityProfileId }
        )?.name ?? "Unknown"
    }

    func detailsRow(_ label: String, value: String) -> some View {
        GridRow(alignment: .top) {
            Text(label)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
                .padding(.trailing)
            Text(value)
            Spacer()
        }
        .font(.callout)
    }

    func informationRow(_ label: String, value: String) -> some View {
        LabeledContent {
            Text(value).foregroundStyle(.primary)
        } label: {
            Text(label).foregroundStyle(.secondary)
        }
    }
}

struct MovieDetailsOverview: View {
    var movie: Movie

    @EnvironmentObject var settings: AppSettings

    let imageSpan = UIDevice.current.userInterfaceIdiom == .phone ? 2 : 1

    var body: some View {
        HStack(alignment: .top) {
            CachedAsyncImage(url: movie.remotePoster, type: .poster)
                .aspectRatio(
                    CGSize(width: 150, height: 225),
                    contentMode: .fill
                )
                .containerRelativeFrame(.horizontal, count: 5, span: imageSpan, spacing: 0)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.trailing, 8)

            VStack(alignment: .leading, spacing: 0) {
                Text(movie.stateLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .foregroundStyle(settings.theme.tint)

                Text(movie.title)
                    .font(shrinkTitle ? .title : .largeTitle)
                    .fontWeight(.bold)
                    .lineLimit(3)
                    .kerning(-0.5)
                    .padding(.bottom, 6)
                    .textSelection(.enabled)

                MovieDetailsSubtitle(movie: movie)

                MovieDetailsRatings(movie: movie)
            }
        }
    }

    var shrinkTitle: Bool {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return movie.title.count > 25
        }

        return false
    }
}

struct MovieDetailsSubtitle: View {
    var movie: Movie

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                Text(String(movie.year))
                Text("•")
                Text(movie.runtimeLabel)

                if movie.certification != nil {
                    Text("•")
                    Text(movie.certification ?? "")
                }
            }

            HStack(spacing: 6) {
                Text(String(movie.year))
                Text("•")
                Text(movie.runtimeLabel)
            }
        }
        .font(.callout)
        .padding(.bottom, 6)
        .foregroundStyle(.secondary)
    }
}

struct MovieDetailsRatings: View {
    var movie: Movie

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                rotten
                imdb
                tmdb
                metacritic
            }

            HStack(spacing: 12) {
                rotten
                imdb
                metacritic
            }

            HStack(spacing: 12) {
                rotten
                imdb
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    var rotten: some View {
        if let rating = movie.ratings?.rottenTomatoes?.value {
            HStack(spacing: 6) {
                Image("rotten").resizable()
                    .scaledToFit()
                    .font(.callout)
                    .frame(height: 14)

                Text(String(format: "%.0f%%", rating))
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    var imdb: some View {
        if let rating = movie.ratings?.imdb?.value {
            HStack(spacing: 6) {
                Image("imdb").resizable()
                    .scaledToFit()
                    .frame(height: 12)

                Text(String(format: "%.1f", rating))
                    .font(.callout)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    var tmdb: some View {
        if let rating = movie.ratings?.tmdb?.value, rating > 0 {
            HStack(spacing: 6) {
                Image("tmdb").resizable()
                    .scaledToFit()
                    .font(.callout)
                    .frame(height: 9)

                Text(String(format: "%.0f%%", rating * 10))
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    var metacritic: some View {
        if let rating = movie.ratings?.metacritic?.value {
            HStack(spacing: 6) {
                Image("metacritic").resizable()
                    .scaledToFit()
                    .font(.callout)
                    .frame(height: 14)

                Text(String(format: "%.0f", rating))
            }
        }
    }
}

#Preview {
    let movies: [Movie] = PreviewData.load(name: "movies")
    let movie = movies.first(where: { $0.id == 235 }) ?? movies[0]

    return MovieSearchSheet(movie: movie)
        .withSettings()
        .withRadarrInstance(movies: movies)
}
