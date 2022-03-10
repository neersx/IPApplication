using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Security
{
    public interface IWebPartSecurity
    {
        bool HasAccessToWebPart(ApplicationWebPart webPart);
    }
}
