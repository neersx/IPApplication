using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Messaging
{
    // Don't make the type parameter variant because
    // Autofac is configured with a contravariant registration
    // source in integration which will cause problems with
    // dispatching messages to the inheritance tree
    // ReSharper disable once TypeParameterCanBeVariant
    public interface IHandle<T>
    {
        void Handle(T message);
    }

    public interface IHandleAsync<T>
    {
        Task HandleAsync(T message);
    }
}