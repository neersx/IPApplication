using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text;
using Newtonsoft.Json;

namespace Inprotech.Tests.Integration.Performance
{
    class Scenario
    {
        string _cookie;

        public List<PageResult> Pages = new List<PageResult>();

        public void Run()
        {
            Page("Login",
                 () => Post("/api/signin", new {username = "internal", password = "internal"}));

            Page("Landing",
                 () => Get("/api/defaultView?menu=yes"));

            Page("Policing dashboard",
                 () =>
                 {
                     Get("/api/enrichment");
                     Get("/api/policing/dashboard/view");
                     Get("/api/policing/dashboard/permissions");
                 });

            Page("Policing all",
                 () => Get("/api/policing/queue/view"));

            Page("Workflow Designer",
                 () =>
                 {
                     Get("/api/enrichment");
                     Get("/api/configuration/rules/workflows/view");
                     Get(@"/api/configuration/rules/workflows/search?criteria={applyTo:null,matchType:""exact-match""}&params={skip:0,take:20}&sortByDescription=true");
                 });

            Page("Signout",
                 () => Get("/api/signout"));
        }

        void Page(string name, Action action)
        {
            var now = DateTime.Now;
            var failed = false;
            try
            {
                action();
            }
            catch
            {
                failed = true;
            }

            Pages.Add(new PageResult
                      {
                          Name = name,
                          Failed = failed,
                          Duration = DateTime.Now - now
                      });
        }

        void Get(string url)
        {
            url = Runtime.TestSubject.DefaultTestInprotechServerRoot + url;

            var req = (HttpWebRequest) WebRequest.Create(url);

            req.Method = WebRequestMethods.Http.Get;
            req.Accept = "application/json, text/plain, */*";
            if (!string.IsNullOrEmpty(_cookie)) req.Headers.Add("Cookie", _cookie);
            var resp = (HttpWebResponse) req.GetResponse();

            if (resp.StatusCode != HttpStatusCode.OK) throw new Exception();

            string response;
            using (var reader = new StreamReader(resp.GetResponseStream()))
                response = reader.ReadToEnd();

            _cookie = _cookie ?? resp.Headers["Set-Cookie"].Split(';')[0];
        }

        void Post(string url, object obj)
        {
            url = Runtime.TestSubject.DefaultTestInprotechServerRoot + url;
            var req = (HttpWebRequest) WebRequest.Create(url);

            req.Method = WebRequestMethods.Http.Post;
            req.Accept = "application/json, text/plain, */*";
            req.ContentType = "application/json;charset=UTF-8";
            if (!string.IsNullOrEmpty(_cookie)) req.Headers.Add("Cookie", _cookie);

            var json = JsonConvert.SerializeObject(obj);
            var bytes = Encoding.UTF8.GetBytes(json);

            req.GetRequestStream().Write(bytes, 0, bytes.Length);
            var resp = (HttpWebResponse) req.GetResponse();

            if (resp.StatusCode != HttpStatusCode.OK) throw new Exception();

            string response;
            using (var reader = new StreamReader(resp.GetResponseStream()))
                response = reader.ReadToEnd();

            _cookie = _cookie ?? resp.Headers["Set-Cookie"].Split(';')[0];
        }
    }

    class PageResult
    {
        public string Name { get; set; }
        public TimeSpan Duration { get; set; }
        public bool Failed { get; set; }

        public override string ToString()
        {
            return Name + " " + Duration;
        }
    }

    class PageAveraged
    {
        public string Name { get; set; }
        public TimeSpan AvgDuration { get; set; }
        public TimeSpan MaxDuration { get; set; }
        public int Failed { get; set; }
    }
}