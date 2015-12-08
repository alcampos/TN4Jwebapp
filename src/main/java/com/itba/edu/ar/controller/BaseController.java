package com.itba.edu.ar.controller;

import java.io.IOException;

import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import pf.Test;

@Controller
public class BaseController {

	private static int counter = 0;
	private static final String VIEW_INDEX = "index";
	private final static org.slf4j.Logger logger = LoggerFactory.getLogger(BaseController.class);

	@RequestMapping(value = "/", method = RequestMethod.GET)
	public String welcome(ModelMap model) {

		model.addAttribute("message", "Welcome");
		model.addAttribute("counter", ++counter);
		model.addAttribute("isMain", true);
		logger.debug("[welcome] counter : {}", counter);

		// Spring uses InternalResourceViewResolver and return back index.jsp
		return VIEW_INDEX;

	}

	@RequestMapping(value = "/query", method = RequestMethod.POST)
	public String query(@RequestParam String query, ModelMap model) {

		model.addAttribute("message", "Welcome " + query);
		model.addAttribute("counter", ++counter);
		model.addAttribute("isMain", false);
		String renderJson = "{\"nodes\":[], \"links\":[]}";
		try {
			Test test = new Test(query);
			renderJson = test.getResultsAsString();
		} catch (Exception e) {
			e.printStackTrace();
		}
		model.addAttribute("json", renderJson);
		logger.debug("[welcomeName] counter : {}", counter);
		return VIEW_INDEX;

	}

}