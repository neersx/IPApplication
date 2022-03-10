namespace InprotechKaizen.Model.Components.Security
{
    public interface IUserNameTokenProvider
    {
        string Name { get; }
        bool TryGetToken(string userName, string password, out string token);
    }
}