using System;

namespace Inprotech.Infrastructure.Security
{
    [Flags]
    public enum ApplicationTaskAccessLevel
    {
        None = 0x00,
        Modify = 0x01,
        Create = 0x02,
        Delete = 0x04,
        Execute = 0x08
    }
}