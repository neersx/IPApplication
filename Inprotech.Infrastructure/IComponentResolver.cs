namespace Inprotech.Infrastructure
{
    public interface IComponentResolver
    {
        int? Resolve(string componentName);
    }
}
