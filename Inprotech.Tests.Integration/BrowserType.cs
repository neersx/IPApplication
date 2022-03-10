using System;

namespace Inprotech.Tests.Integration
{
    [Flags]
    public enum BrowserType
    {
        Default = 1,
        NoBrowser = 2,
        Ie = 4,
        Chrome = 8,
        FireFox = 16
    }
}