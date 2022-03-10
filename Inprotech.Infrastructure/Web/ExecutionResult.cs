namespace Inprotech.Infrastructure.Web
{
    public class ExecutionResult
    {
        public ExecutionResult()
        {
            IsSuccess = true;
        }

        public ExecutionResult(string key)
        {
            IsSuccess = false;
            Key = key;
            Error = string.Empty;
        }
        public ExecutionResult(string key, string message)
        {
            IsSuccess = false;
            Key = key;
            Error = message;
        }

        public bool IsSuccess { get; set; }
        public string Key { get; set; }
        public string Error { get; set; }
    }
}
