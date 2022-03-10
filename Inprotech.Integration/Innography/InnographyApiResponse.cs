using System.Runtime.Serialization;
using Newtonsoft.Json.Serialization;

namespace Inprotech.Integration.Innography
{
    public class InnographyApiResponse<T>
    {
        public InnographyApiResponse()
        {
            Result = new T[0];
        }

        public string Message { get; set; }

        public string Status { get; set; }

        public string Version { get; set; }

        public T[] Result { get; set; }

        public string ErrorMessage { get; set; }

        [OnError]
        internal void OnError(StreamingContext context, ErrorContext errorContext)
        {
            var member = errorContext.Member as string;
            if (member == "result")
            {
                ErrorMessage = errorContext.Error.Message;
                errorContext.Handled = true;
            }
        }
    }
}