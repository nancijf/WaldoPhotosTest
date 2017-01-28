//  This file was automatically generated and should not be edited.
//  Uses apollo-codegen to retreive the schema and generate this file with the Graphql Query file

import Apollo

public final class AlbumQuery: GraphQLQuery {
  public static let operationDefinition =
    "query Album($offset: Int!) {" +
    "  album(id: \"YWxidW06YTQwYzc5ODEtMzE1Zi00MWIyLTk5NjktMTI5NjIyZDAzNjA5\") {" +
    "    id" +
    "    name" +
    "    photos(slice: {limit: 50, offset: $offset}) {" +
    "      records {" +
    "        urls {" +
    "          size_code" +
    "          url" +
    "          width" +
    "          height" +
    "          quality" +
    "          mime" +
    "        }" +
    "      }" +
    "    }" +
    "  }" +
    "}"

  public let offset: Int

  public init(offset: Int) {
    self.offset = offset
  }

  public var variables: GraphQLMap? {
    return ["offset": offset]
  }

  public struct Data: GraphQLMappable {
    public let album: Album?

    public init(reader: GraphQLResultReader) throws {
      album = try reader.optionalValue(for: Field(responseName: "album"))
    }

    public struct Album: GraphQLMappable {
      public let __typename = "Album"
      public let id: String
      public let name: String?
      public let photos: Photo?

      public init(reader: GraphQLResultReader) throws {
        id = try reader.value(for: Field(responseName: "id"))
        name = try reader.optionalValue(for: Field(responseName: "name"))
        photos = try reader.optionalValue(for: Field(responseName: "photos"))
      }

      public struct Photo: GraphQLMappable {
        public let __typename = "Photos"
        public let records: [Record?]?

        public init(reader: GraphQLResultReader) throws {
          records = try reader.optionalList(for: Field(responseName: "records"))
        }

        public struct Record: GraphQLMappable {
          public let __typename = "Photo"
          public let urls: [Url?]?

          public init(reader: GraphQLResultReader) throws {
            urls = try reader.optionalList(for: Field(responseName: "urls"))
          }

          public struct Url: GraphQLMappable {
            public let __typename = "PhotoURLType"
            public let sizeCode: String?
            public let url: String?
            public let width: Int?
            public let height: Int?
            public let quality: Double?
            public let mime: String?

            public init(reader: GraphQLResultReader) throws {
              sizeCode = try reader.optionalValue(for: Field(responseName: "size_code"))
              url = try reader.optionalValue(for: Field(responseName: "url"))
              width = try reader.optionalValue(for: Field(responseName: "width"))
              height = try reader.optionalValue(for: Field(responseName: "height"))
              quality = try reader.optionalValue(for: Field(responseName: "quality"))
              mime = try reader.optionalValue(for: Field(responseName: "mime"))
            }
          }
        }
      }
    }
  }
}
