namespace Inprotech.Tests.Web.Builders
{
    public interface IBuilder<out T> where T : class
    {
        T Build();
    }
}