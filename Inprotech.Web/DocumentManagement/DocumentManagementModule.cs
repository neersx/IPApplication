using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Autofac;

namespace Inprotech.Web.DocumentManagement
{
    class DocumentManagementModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<UrlTester>().As<IUrlTester>();
        }
    }
}
