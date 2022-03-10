namespace Inprotech.Tests
{
    public interface IFixture<T>
    {
        T Subject { get; }
    }
}