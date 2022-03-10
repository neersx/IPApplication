using System;

namespace Inprotech.Tests.Integration
{
    public enum TestTypes
    {
        Scenario,
        Regression
    }

    [AttributeUsage(AttributeTargets.Class)]
    public class TestTypeAttribute : Attribute
    {
        public TestTypeAttribute(TestTypes testType)
        {
            TestType = testType;
        }

        public TestTypes TestType { get; private set; }
    }
}