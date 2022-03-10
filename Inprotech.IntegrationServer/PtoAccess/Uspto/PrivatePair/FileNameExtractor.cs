using System;
using System.IO;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public interface IFileNameExtractor
    {
        string AbsoluteUriName(string uri);
    }

    public class FileNameExtractor : IFileNameExtractor
    {
        public string AbsoluteUriName(string uri) => Path.GetFileName(new Uri(uri).LocalPath);
    }
}