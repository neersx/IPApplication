using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace Inprotech.Infrastructure
{
    public class FileTypeExtension
    {
        public const string Bitmap = ".bmp";
        public const string PortableNetworkGraphic = ".png";
        public const string Jpeg = ".jpg";
        public const string GraphicsInterchangeFormat87A = ".gif";
        public const string GraphicsInterchangeFormat89A = ".gif";

        public const string PortableDocumentFormat = ".pdf";
        public const string WindowsDosExecutableFile = ".exe";
        public const string UnKnown = "";
    }

    public abstract class FileTypeMatcher
    {
        public bool Matches(Stream stream, bool resetPosition = true)
        {
            if (stream == null)
            {
                throw new ArgumentNullException(nameof(stream));
            }

            if (!stream.CanRead || stream.Position != 0 && !stream.CanSeek)
            {
                throw new ArgumentException(nameof(stream));
            }

            if (stream.Position != 0 && resetPosition)
            {
                stream.Position = 0;
            }

            return MatchesPrivate(stream);
        }

        protected abstract bool MatchesPrivate(Stream stream);
    }

    public class ExactFileTypeMatcher : FileTypeMatcher
    {
        readonly byte[] _bytes;

        public ExactFileTypeMatcher(IEnumerable<byte> bytes)
        {
            _bytes = bytes.ToArray();
        }

        protected override bool MatchesPrivate(Stream stream)
        {
            foreach (var b in _bytes)
            {
                if (stream.ReadByte() != b)
                {
                    return false;
                }
            }

            return true;
        }
    }

    public class FuzzyFileTypeMatcher : FileTypeMatcher
    {
        readonly byte?[] _bytes;

        public FuzzyFileTypeMatcher(IEnumerable<byte?> bytes)
        {
            _bytes = bytes.ToArray();
        }

        protected override bool MatchesPrivate(Stream stream)
        {
            foreach (var b in _bytes)
            {
                var c = stream.ReadByte();
                if (c == -1 || b.HasValue && c != b.Value)
                {
                    return false;
                }
            }

            return true;
        }
    }

    public class RangeFileTypeMatcher : FileTypeMatcher
    {
        readonly int _maximumStartLocation;
        public readonly FileTypeMatcher _matcher;

        public RangeFileTypeMatcher(FileTypeMatcher matcher, int maximumStartLocation)
        {
            _matcher = matcher;
            _maximumStartLocation = maximumStartLocation;
        }

        protected override bool MatchesPrivate(Stream stream)
        {
            for (var i = 0; i < _maximumStartLocation; i++)
            {
                // Might want to check if i >= stream.Length.
                stream.Position = i;
                if (_matcher.Matches(stream, false))
                {
                    return true;
                }
            }

            return false;
        }
    }

    public class FileType
    {
        readonly FileTypeMatcher _fileTypeMatcher;

        public FileType(string name, string extension, FileTypeMatcher matcher)
        {
            Name = name;
            Extension = extension;
            _fileTypeMatcher = matcher;
        }

        public string Name { get; }

        public string Extension { get; }

        public static FileType Unknown { get; } = new FileType("UnKnown", FileTypeExtension.UnKnown, null);

        public bool Matches(Stream stream)
        {
            return _fileTypeMatcher == null || _fileTypeMatcher.Matches(stream);
        }
    }

    public interface IFileTypeChecker
    {
        FileType GetFileType(Stream fileContent);
    }

    class FileTypeChecker : IFileTypeChecker
    {
        static readonly IList<FileType> KnownFileTypes =
            new List<FileType>
            {
                new FileType("Bitmap", FileTypeExtension.Bitmap, new ExactFileTypeMatcher(new byte[] {0x42, 0x4d})),
                new FileType("Portable Network Graphic", FileTypeExtension.PortableNetworkGraphic, new ExactFileTypeMatcher(new byte[] {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A})),
                new FileType("JPEG", FileTypeExtension.Jpeg, new FuzzyFileTypeMatcher(new byte?[] {0xFF, 0xD, 0xFF, 0xE0, null, null, 0x4A, 0x46, 0x49, 0x46, 0x00})),
                new FileType("Graphics Interchange Format 87a", FileTypeExtension.GraphicsInterchangeFormat87A, new ExactFileTypeMatcher(new byte[] {0x47, 0x49, 0x46, 0x38, 0x37, 0x61})), new FileType("Graphics Interchange Format 89a", FileTypeExtension.GraphicsInterchangeFormat89A, new ExactFileTypeMatcher(new byte[] {0x47, 0x49, 0x46, 0x38, 0x39, 0x61})),
                new FileType("Portable Document Format", FileTypeExtension.PortableDocumentFormat, new RangeFileTypeMatcher(new ExactFileTypeMatcher(new byte[] {0x25, 0x50, 0x44, 0x46}), 1019)),

                new FileType("Windows/DOS executable file", FileTypeExtension.WindowsDosExecutableFile, new ExactFileTypeMatcher(new byte[] {0x4D, 0x5A}))
                // ... Potentially more in future
            };

        public FileType GetFileType(Stream fileContent)
        {
            return GetFileTypes(fileContent).FirstOrDefault() ?? FileType.Unknown;
        }

        public IEnumerable<FileType> GetFileTypes(Stream stream)
        {
            return KnownFileTypes.Where(fileType => fileType.Matches(stream));
        }
    }
}