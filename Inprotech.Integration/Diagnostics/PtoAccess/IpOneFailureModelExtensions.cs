using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Integration.Innography.PrivatePair;
using Newtonsoft.Json;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    public static class IpOneFailureModelExtension
    {
        public static IEnumerable<Message> Messages(this IpOneFailures.IpOneFailureModel model)
        {
            if (string.IsNullOrEmpty(model.State))
            {
                return Enumerable.Empty<Message>();
            }

            try
            {
                return JsonConvert.DeserializeObject<IEnumerable<Message>>(model.State);
            }
            catch (JsonException e)
            {
                return Enumerable.Empty<Message>();
            }
        }
    }
}
