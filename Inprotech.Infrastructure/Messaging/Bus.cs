using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Autofac;
using Inprotech.Contracts.Messages;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Infrastructure.Messaging
{
    public interface IBus
    {
        void Publish<T>(T message) where T : Message;

        Task PublishAsync<T>(T message) where T : Message;
    }

    internal class Bus : IBus
    {
        readonly Func<ILifetimeScope> _lifetimeScope;
        readonly Func<ICurrentRequestLifetimeScope> _requestLifetimeScope;

        public Bus(Func<ILifetimeScope> lifetimeScope, Func<ICurrentRequestLifetimeScope> requestLifetimeScope)
        {
            _lifetimeScope = lifetimeScope;
            _requestLifetimeScope = requestLifetimeScope;
        }

        public void Publish<T>(T message) where T : Message
        {
            foreach (var type in AllAncestryTypesAndSelf(message)) Dispatch(message, type);
        }

        public async Task PublishAsync<T>(T message) where T : Message
        {
            foreach (var type in AllAncestryTypesAndSelf(message)) await DispatchAsync(message, type);
        }

        static IEnumerable<Type> AllAncestryTypesAndSelf<T>(T message) where T : Message
        {
            var type = message.GetType();
            yield return type;

            do
            {
                type = type.BaseType;
                yield return type;
            }
            while (type != typeof(Message) && type != null);
        }

        void Dispatch(dynamic message, Type type)
        {
            var handlers = Resolve(type, typeof(IHandle<>));
            foreach (var handler in handlers) handler.Handle(message);
        }

        async Task DispatchAsync(dynamic message, Type type)
        {
            var handlers = Resolve(type, typeof(IHandleAsync<>));
            foreach (var handler in handlers) await handler.HandleAsync(message);
        }

        IEnumerable<dynamic> Resolve(Type type, Type handlerType)
        {
            var typeToResolve = typeof(IEnumerable<>).MakeGenericType(handlerType.MakeGenericType(type));
            var resolver = _requestLifetimeScope();
            if (resolver.TryResolve(typeToResolve, out var component) && ((IEnumerable<dynamic>) component).Any())
            {
                return (IEnumerable<dynamic>) component;
            }

            return (IEnumerable<dynamic>) _lifetimeScope().Resolve(typeToResolve);
        }
    }
}