using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace Inprotech.Infrastructure.Storage
{
    public interface IContentHasher
    {
        string ComputeHash(string content);
    }

    public class ContentHasher : IContentHasher
    {
        public string ComputeHash(string content)
        {
            if (string.IsNullOrEmpty(content)) throw new ArgumentNullException("content");

            using (var memoryStream = new MemoryStream(Encoding.Default.GetBytes(content)))
            using (var sha1 = new SHA1Managed())
            {
                var hash = sha1.ComputeHash(memoryStream);
                return Convert.ToBase64String(hash);
            }
        }
    }
}