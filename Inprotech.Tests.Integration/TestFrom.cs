using System;

namespace Inprotech.Tests.Integration
{
    [AttributeUsage(AttributeTargets.Class)]
    public class TestFrom : Attribute
    {
        public int DbCompatLevel { get; }

        public TestFrom(int dbReleaseLevel)
        {
            DbCompatLevel = dbReleaseLevel;
        }
    }

    public static class DbCompatLevel
    {
        public const int Release13 = 13;
        public const int Release14 = 14;
        public const int Release15 = 15;
        public const int Release16 = 16;
    }
}