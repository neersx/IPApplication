using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.SchemaMapping.XmlGen;
using Newtonsoft.Json;

namespace Inprotech.Integration.SchemaMapping.Data
{
    class DocItem
    {
        public DocItem()
        {
            Parameters = Enumerable.Empty<DocItemParameter>();
        }

        public int Id { get; set; }

        public string Name { get; set; }

        public IEnumerable<DocItemParameter> Parameters;

        [JsonIgnore]
        public IDictionary<string, object> CachedParameters { get; private set; }

        public IDictionary<string, object> BuildParameters(IGlobalContext globalContext)
        {
            if (CachedParameters == null)
            {
                CachedParameters = Parameters.ToDictionary(param => param.Id, param =>
                {
                    if (param is FixedParameter)
                        return ((FixedParameter) param).Value;

                    if (param is GlobalParameter)
                        return globalContext.GetParameter(param.Id);

                    throw XmlGenExceptionHelper.ParameterTypeNotSupported(param.Type);
                });
            }
                
            return CachedParameters;
        }
    }
}