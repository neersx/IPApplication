﻿using Autofac;

namespace Inprotech.Web.Configuration.Offices
{
    public class OfficeModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<Offices>().As<IOffices>();
        }
    }
}
