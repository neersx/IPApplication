using System.IO;
using System.Text;

namespace Inprotech.Infrastructure
{
    public class EncodingStringWriter : StringWriter
    {
        readonly Encoding _encoding;

        public EncodingStringWriter(Encoding encoding) : this(new StringBuilder(), encoding)
        {
            
        }

        public EncodingStringWriter(StringBuilder builder, Encoding encoding)
            : base(builder)
        {
            _encoding = encoding;
        }

        public override Encoding Encoding => _encoding;
    }
}
