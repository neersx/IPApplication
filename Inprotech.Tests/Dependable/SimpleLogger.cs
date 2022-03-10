using System.Runtime.CompilerServices;
using System.Text;
using Dependable.Tracking;

namespace Inprotech.Tests.Dependable
{
    public class SimpleLogger
    {
        readonly StringBuilder _log = new StringBuilder();

        public void Log(EventType type, string message)
        {
            _log.AppendLine(type + " " + message);
        }

        public void Write<T>(T type, string message,
                             [CallerMemberName] string memberName = "")
        {
            _log.AppendLine(typeof(T).Name + "." + memberName + ": " + message);
        }

        public string Collected()
        {
            return _log.ToString().Trim();
        }
    }
}