using System.Configuration;

namespace Inprotech.Infrastructure
{
    public interface IConnectionStrings
    {
        string this[string index] { get; }
    }

    public class ConnectionStrings : IConnectionStrings
    {
        public string this[string index] => ConfigurationManager.ConnectionStrings[index].ToString();
    }
}