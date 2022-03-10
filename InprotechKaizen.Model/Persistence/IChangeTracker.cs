namespace InprotechKaizen.Model.Persistence
{
    public interface IChangeTracker
    {
        bool HasChanged(object instance);
    }
}