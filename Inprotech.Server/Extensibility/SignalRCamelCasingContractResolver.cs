using System;
using System.Reflection;
using Microsoft.AspNet.SignalR.Infrastructure;
using Newtonsoft.Json.Serialization;

namespace Inprotech.Server.Extensibility
{
    public class SignalRCamelCasingContractResolver : IContractResolver
    {
        readonly Assembly _assembly;
        readonly IContractResolver _camelCaseContractResolver;
        readonly IContractResolver _defaultContractSerializer;

        public SignalRCamelCasingContractResolver()
        {
            _defaultContractSerializer = new DefaultContractResolver();
            _camelCaseContractResolver = new CamelCasePropertyNamesContractResolver();
            _assembly = typeof(Connection).Assembly;
        }

        public JsonContract ResolveContract(Type type)
        {
            if (type == null) throw new ArgumentNullException(nameof(type));

            if (type.Assembly.Equals(_assembly))
            {
                return _defaultContractSerializer.ResolveContract(type);
            }

            return _camelCaseContractResolver.ResolveContract(type);
        }
    }
}
