namespace Inprotech.Contracts.Settings
{
    public interface ISettings
    {
        string this[string key] { get; set; }
        void Delete(string key);
        T GetValueOrDefault<T>(string key, T defaultValue);
        T GetValueOrDefault<T>(string key);
        void SetValue<T>(string key, T value);
    }

    public interface IGroupedSettings : ISettings
    {
    }
}