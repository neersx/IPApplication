using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;
using Inprotech.Web.BulkCaseImport;
using Newtonsoft.Json.Linq;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport
{
    public class XmlIllegalCharSanitiserFacts
    {
        public static IEnumerable<object[]> InvalidXmlData
        {
            get
            {
                object[] CreatePair(byte invalidChar)
                {
                    var start = Fixture.String();
                    var end = Fixture.String();

                    var input = start + end;
                    var invalidInput = start + Encoding.UTF8.GetString(new[] { invalidChar }) + end;

                    return new[] { $"{invalidChar}", input, invalidInput };
                }

                for (byte i = 0x1; i < 0x8; i++) yield return CreatePair(i);
                for (byte i = 0xB; i < 0xC; i++) yield return CreatePair(i);
                for (byte i = 0xE; i < 0x1F; i++) yield return CreatePair(i);
            }
        }

        [Fact]
        public void ShouldReturnFalseIfNothingWasSanitised()
        {
            var row = Fixture.Integer();
            var fieldName = Fixture.String();
            var fieldValue = Fixture.String();
            var prop = new JProperty(fieldName, fieldValue);
            var subject = new XmlIllegalCharSanitiser();
            Assert.False(subject.TrySanitise(prop, row, out _));
            Assert.Equal(fieldName, prop.Name);
            Assert.Equal(fieldValue, prop.Value);
        }

        [Theory]
        [MemberData(nameof(InvalidXmlData))]
#pragma warning disable xUnit1026
        public void ShouldReturnTrueWithSanitisedValue(string invalidChar, string sanitised, string input)
#pragma warning restore xUnit0000
        {
            var row = Fixture.Integer();
            var fieldName = Fixture.String();
            var prop = new JProperty(fieldName, input);
            var subject = new XmlIllegalCharSanitiser();

            Assert.True(subject.TrySanitise(prop, row, out var invalid));
            Assert.Equal(fieldName, prop.Name);
            Assert.Equal(sanitised, (string)prop.Value);

            Assert.Equal(row, invalid.Row);
            Assert.Equal(fieldName, invalid.FieldName);
            Assert.Equal(input, invalid.OriginalValue);
            Assert.Equal(sanitised, invalid.SanitisedValue);

            Assert.True(((string)prop.Value).All(XmlConvert.IsXmlChar));
        }

        [Theory]
        [InlineData(0xA0)]
        [InlineData(0xFFFD)]
        public void SanitizeUnsupportedUnicode(char unsupported)
        {
            var fieldName = Fixture.String();
            var sanitized = Fixture.String();
            var row = Fixture.Integer();
            var input = $"{ sanitized + unsupported}";
            var prop = new JProperty(fieldName, input);
            var subject = new XmlIllegalCharSanitiser();

            Assert.True(subject.TrySanitise(prop, row, out var invalid));

            Assert.Equal(row, invalid.Row);
            Assert.Equal(fieldName, invalid.FieldName);
            Assert.Equal(input, invalid.OriginalValue);
            Assert.Equal(sanitized, invalid.SanitisedValue);
        }
    }
}