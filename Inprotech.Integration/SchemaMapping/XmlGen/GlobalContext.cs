using System.Collections.Generic;

namespace Inprotech.Integration.SchemaMapping.XmlGen
{
    interface IGlobalContext
    {
        object GetParameter(string name);
    }

    class GlobalContext : IGlobalContext
    {
        readonly IDictionary<string, object> _parameters;

        public GlobalContext(IDictionary<string, object> parameters)
        {
            _parameters = parameters ?? new Dictionary<string, object>();
        }

        public object GetParameter(string name)
        {
            if (!_parameters.ContainsKey(name))
                throw XmlGenExceptionHelper.GlobalParameterNotFound(name);

            return _parameters[name];
        }
    }
}
