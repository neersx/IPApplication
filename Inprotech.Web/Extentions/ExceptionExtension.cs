using System;

namespace Inprotech.Web.Extentions
{
    public static class ExceptionExtension
    {        
        public static T FindInnerException<T>(this Exception ex) where T : Exception
        {
            if (ex.GetType() == typeof(T)) return (T)ex;
            var inner = ex.InnerException;
            if (inner == null)
            {
                return null;
            }
            if (inner.GetType() == typeof(T))
            {
                return (T)inner;
            }
            return inner.FindInnerException<T>();
        }
    }
}
