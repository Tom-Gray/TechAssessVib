using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace VibApp
{   
    public class Responder : Controller
    {
        [HttpGet]
        [Route("/")]
        public IActionResult Get()
        {
                
                return Content("Replace this message with data from the database");
            }
        }
    }

