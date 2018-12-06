using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;

namespace VibApp
{
    public class Responder : Controller
    {
        IConfiguration Configuration { get; }

        public Checker(IConfiguration configuration)
        {
            Configuration = configuration;
        }
        [HttpGet]
        [Route("/")]
        public IActionResult Get()
        {
            //create connection string 
            string connectionString = Configuration["ConnectionString"];
            //The Using keyword means we'll automatically drop the sql connection after the Return.
            using (var connection = new SqlConnection(connectionString))
            {
                if (connection.State != System.Data.ConnectionState.Open)
                    connection.Open();
                //build the query string
                const string query = Configuration["Query"];
                //build the command to execute
                var command = new SqlCommand(query, connection);
                //return the result as a string to the caller.
                return Content(command.ExecuteScalar().ToString());
            }
        }
    }
}
