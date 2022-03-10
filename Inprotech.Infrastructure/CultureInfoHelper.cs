using System;
using System.Globalization;
using System.Threading;

namespace Inprotech.Infrastructure
{
    public static class CultureInfoHelper
    {
        public static IDisposable SetDefault()
        {
            return new DefaultCulture();
        }
    }

    public class DefaultCulture : IDisposable
    {
        readonly CultureInfo _originalCulture;

        public DefaultCulture()
        {
            if (Thread.CurrentThread.CurrentCulture.TextInfo.ANSICodePage != 0) return;
            _originalCulture = Thread.CurrentThread.CurrentCulture;
            Thread.CurrentThread.CurrentCulture = CultureInfo.InvariantCulture;
        }

        public void Dispose()
        {
            if(_originalCulture != null)
                Thread.CurrentThread.CurrentCulture = _originalCulture;
        }
    }
}
