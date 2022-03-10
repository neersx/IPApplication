using System;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

namespace Inprotech.Infrastructure.Security
{
    public static class Hash
    {
        public static string Md5(string source)
        {            
            using (var md5Hash = MD5.Create())
            {
                return GetMd5Hash(md5Hash, source);
            }
        }

        // refer to: https://msdn.microsoft.com/en-us/library/system.security.cryptography.md5.aspx
        static string GetMd5Hash(MD5 md5Hash, string input)
        {
            var data = md5Hash.ComputeHash(Encoding.UTF8.GetBytes(input));
            return String.Join(string.Empty, data.Select(b => b.ToString("x2")));
        }
    }
}
