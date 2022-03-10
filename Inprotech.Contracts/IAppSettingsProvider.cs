namespace Inprotech.Contracts
{
    public interface IAppSettingsProvider
    {
        string this[string index] { get; }
    }
}