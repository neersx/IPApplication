using System;
using AutoMapper;

namespace Inprotech.Web.InproDoc.Converter
{
    public class ExceptionTypeConverter : ITypeConverter<Exception, string>
    {
        public string Convert(Exception source, string destination, ResolutionContext context)
        {
            if (source == null) return null;

            if (source.InnerException == null) return source.Message;
            return source.Message + Environment.NewLine + source.InnerException.Message;
        }
    }
}