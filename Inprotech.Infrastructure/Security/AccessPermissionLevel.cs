using System;

namespace Inprotech.Infrastructure.Security
{
    [Flags]
    public enum AccessPermissionLevel
    {
        Select = 0x01, // 00000000 = 1
        Delete = 0x02, // 00000001 = 2
        Insert = 0x04, // 00000010 = 4
        Update = 0x08, // 00000100 = 8
        FullAccess = 0xf //15
    }
}