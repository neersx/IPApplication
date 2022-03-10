using System;
using System.Linq;
using System.Xml.Schema;

namespace Inprotech.Integration.SchemaMapping.XmlGen.Formatters
{
    class DateYearMonthFormatter : IXmlSchemaTypeFormatter
    {
        const string DefaultFormat = "yyyy-MM-dd";
        string _format;

        public bool Supports(XmlSchemaType type, object value)
        {
            _format = DefaultFormat;
            var supports = value is DateTime && new[] {XmlTypeCode.GDay, XmlTypeCode.GMonth, XmlTypeCode.GMonthDay, XmlTypeCode.GYear, XmlTypeCode.GYearMonth}.Contains(type.TypeCode);
            if (supports)
            {
                SetFormat(type.TypeCode);
            }

            return supports;
        }

        public object Format(object value)
        {
            if (value == null)
                return null;

            return ((DateTime) value).ToString(_format);
        }

        void SetFormat(XmlTypeCode code)
        {
            switch (code)
            {
                case XmlTypeCode.GDay:
                    _format = "dd";
                    break;
                case XmlTypeCode.GMonth:
                    _format = "MM";
                    break;
                case XmlTypeCode.GMonthDay:
                    _format = "MM-dd";
                    break;
                case XmlTypeCode.GYear:
                    _format = "yyyy";
                    break;
                case XmlTypeCode.GYearMonth:
                    _format = "yyyy-MM";
                    break;
            }
        }
    }
}