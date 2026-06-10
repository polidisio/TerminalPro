import SwiftUI

struct ServerRow: View {
    let server: Server
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "server.rack")
                .font(.title2)
                .foregroundStyle(accent)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(server.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)

                Text("\(server.username)@\(server.host):\(server.port)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.gray)
            }

            Spacer()

            if server.isDefault {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 4)
    }
}