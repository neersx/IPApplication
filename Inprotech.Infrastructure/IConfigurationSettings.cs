namespace Inprotech.Infrastructure
{
    public interface IConfigurationSettings
    {
        string this[string index] { get; }
    }
}