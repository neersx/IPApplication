using System;
using System.Xml.Schema;
using Inprotech.Integration.SchemaMapping.XmlGen.Formatters;
using Xunit;

namespace Inprotech.Tests.Integration.SchemaMapping.Formatters
{
    public class DateFormatterFacts
    {
        public DateFormatterFacts()
        {
            _formatter = new DateFormatter();
        }

        readonly IXmlSchemaTypeFormatter _formatter;

        [Fact]
        public void ShouldCheckForNullValue()
        {
            var val = _formatter.Format(null);
            Assert.Null(val);
        }

        [Fact]
        public void ShouldNotSupportInvalidDate()
        {
            var date = 1;
            var type = XmlSchemaType.GetBuiltInSimpleType(XmlTypeCode.Date);
            Assert.False(_formatter.Supports(type, date));
        }

        [Fact]
        public void ShouldNotSupportInvalidType()
        {
            var type = XmlSchemaType.GetBuiltInSimpleType(XmlTypeCode.DateTime);
            Assert.False(_formatter.Supports(type, Fixture.Today()));
        }

        [Fact]
        public void ShouldReturnFormattedDate()
        {
            var date = new DateTime(2000, 1, 20);
            var val = _formatter.Format(date);
            Assert.Equal("2000-01-20", val);
        }

        [Fact]
        public void ShouldSupportValidTypeAndDate()
        {
            var type = XmlSchemaType.GetBuiltInSimpleType(XmlTypeCode.Date);
            Assert.True(_formatter.Supports(type, Fixture.Today()));
        }
    }
}