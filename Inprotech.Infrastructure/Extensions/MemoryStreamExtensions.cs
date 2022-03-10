using System.IO;

namespace Inprotech.Infrastructure.Extensions
{
    public static class MemoryStreamExtensions
    {
        public static byte[] ToByteArray(this Stream @this)
        {
            using (var ms = new MemoryStream())
            {
                @this.CopyTo(ms);
                return ms.ToArray();
            }
        }
    }
}
