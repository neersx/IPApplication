using System.IO;
using System.IO.Compression;
using System.Linq;
using InprotechKaizen.Model;

namespace Inprotech.Web.Cases.Details
{
    public interface IEfilingFileViewer
    {
        Stream OpenFileFromZip(byte[] zipFile, string fileToOpen);
    }

    public class EfilingFileViewer : IEfilingFileViewer
    {
        public Stream OpenFileFromZip(byte[] zipFile, string fileToOpen)
        {
            var stream = new MemoryStream(zipFile);
            var zipFileEntry = new ZipArchive(stream, ZipArchiveMode.Read, true).Entries;
            var file = zipFileEntry.FirstOrDefault(v => v.Name == fileToOpen) 
                ?? zipFileEntry.FirstOrDefault(v => v.Name.ToLower().Contains(KnownFileExtensions.Mpx)
                && fileToOpen.ToLower().Contains(KnownFileExtensions.Mpx));
            return file?.Open();
        }
    }
}
