using System.Web;

namespace Inprotech.Web
{
    public enum SqlExceptionType
    {
        ForeignKeyConstraintViolationsOnDelete = 547
    }

    public static class Exceptions
    {
        public static HttpException NotFound(string message)
        {
            return new HttpException(404, message);
        }

        public static HttpException NotFound(string format, params object[] args)
        {
            return NotFound(string.Format(format, args));
        }

        public static HttpException BadRequest(string message)
        {
            return new HttpException(400, message);
        }

        public static HttpException BadRequest(string format, params object[] args)
        {
            return BadRequest(string.Format(format, args));
        }

        public static HttpException Forbidden(string message)
        {
            return new HttpException(403, message);
        }

        public static HttpException Forbidden(string format, params object[] args)
        {
            return Forbidden(string.Format(format, args));
        }
    }
}